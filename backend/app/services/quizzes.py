"""Quiz generation and grading.

`generate_quiz` orchestrates a Claude call to produce type-specific questions and
persists the resulting quiz. `grade_quiz_submission` grades a user's attempt:
open-ended answers are graded semantically by Claude, while mcq/tf/fill are
auto-graded against their stored correct answers.
"""
from sqlalchemy.orm import Session

from app.claude_client import ClaudeClient
from app.models import Clause, Quiz, QuizAttempt

QUIZ_GENERATION_SYSTEM = (
    "You generate quiz questions for English learners reading legal contracts. "
    'Return JSON: {"questions": [...]}. EVERY question object MUST include a '
    '"type" field ("mcq", "tf", "fill" or "open") plus its type-specific '
    "answer fields."
)

QUIZ_GRADING_SYSTEM = (
    "You grade a user's answer to a comprehension question. "
    'Return JSON: {"score": 0.0-1.0, "feedback": "explanation"}'
)


def generate_quiz(
    db: Session,
    claude: ClaudeClient,
    clause_id: int | None = None,
    contract_id: int | None = None,
    quiz_type: str = "mcq",
    count: int = 1,
) -> Quiz:
    """Generate a quiz and persist it."""
    if not clause_id and not contract_id:
        raise ValueError("Either clause_id or contract_id is required")

    clause = db.get(Clause, clause_id) if clause_id else None
    context = clause.original_text if clause else f"Contract #{contract_id}"

    user_prompt = (
        f"Generate {count} {quiz_type} questions for this contract text:\n\n{context}\n\n"
        f"Question type: {quiz_type}\n"
        f"For MCQ: include 4 options with correct_index.\n"
        f"For TF (true/false): include correct answer (true/false).\n"
        f"For fill-blank: provide blank position and correct word(s).\n"
        f"For open: comprehension question that tests deep understanding."
    )

    response = claude.complete_json(QUIZ_GENERATION_SYSTEM, user_prompt)
    questions = response.get("questions", [])

    quiz = Quiz(
        clause_id=clause_id,
        contract_id=contract_id,
        quiz_type=quiz_type,
        questions=questions,
    )
    db.add(quiz)
    db.commit()
    db.refresh(quiz)
    return quiz


def grade_quiz_submission(
    db: Session,
    claude: ClaudeClient,
    attempt: QuizAttempt,
) -> None:
    """Grade a user's quiz submission and update the attempt."""
    db.refresh(attempt)
    quiz = attempt.quiz
    questions = quiz.questions

    if quiz.quiz_type == "open":
        # Use Claude to grade open-ended answers semantically.
        user_answers_text = "\n".join(
            f"Q: {q.get('question')}\nA: {ans}"
            for q, ans in zip(questions, attempt.answers)
        )
        grade_prompt = f"Grade these answers:\n\n{user_answers_text}"
        grade_response = claude.complete_json(QUIZ_GRADING_SYSTEM, grade_prompt)
        attempt.score = grade_response.get("score", 0.0)
        attempt.feedback = grade_response.get("feedback")
    else:
        # Auto-grade MCQ/TF/fill against their stored correct answers.
        # The AI sometimes omits the per-question "type" field; fall back to
        # the quiz-level type so grading never crashes on a missing key.
        score = 0.0
        for q, user_ans in zip(questions, attempt.answers):
            qtype = q.get("type") or quiz.quiz_type
            if qtype == "mcq" and user_ans == q.get("correct_index"):
                score += 1.0 / len(questions)
            elif qtype == "tf" and user_ans == q.get("correct"):
                score += 1.0 / len(questions)
            elif (
                qtype == "fill"
                and isinstance(user_ans, str)
                and user_ans.lower() == q.get("correct_word", "").lower()
            ):
                score += 1.0 / len(questions)
        attempt.score = score
        attempt.feedback = f"Scored {int(score * 100)}%"

    db.commit()
