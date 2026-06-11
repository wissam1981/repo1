from dataclasses import dataclass
from datetime import timedelta


@dataclass
class ReviewState:
    ease: float
    interval_days: int
    repetitions: int

    def __post_init__(self):
        if self.ease < 1.3:
            self.ease = 1.3


class InitialReview(ReviewState):
    def __init__(self):
        super().__init__(ease=2.5, interval_days=1, repetitions=0)


def apply_sm2(state: ReviewState, quality: int) -> ReviewState:
    """
    Apply SM-2 algorithm. quality is 0–5: 0=complete blackout, 5=perfect answer.
    quality < 3 is considered incorrect (reset). quality >= 3 is correct (advance).
    """
    if quality < 3:
        # Incorrect: reset
        return ReviewState(
            ease=max(1.3, state.ease - 0.2),
            interval_days=1,
            repetitions=0,
        )
    else:
        # Correct: advance
        reps = state.repetitions + 1
        if reps == 1:
            interval = 3
        elif reps == 2:
            interval = int(state.interval_days * state.ease)
        else:
            interval = int(state.interval_days * state.ease)
        return ReviewState(
            ease=state.ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)),
            interval_days=max(1, interval),
            repetitions=reps,
        )
