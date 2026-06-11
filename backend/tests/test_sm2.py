from app.sm2 import apply_sm2, InitialReview

def test_initial_review():
    initial = InitialReview()
    assert initial.ease == 2.5
    assert initial.interval_days == 1
    assert initial.repetitions == 0

def test_correct_answer_advances_schedule():
    state = InitialReview()
    # First correct review: 1 day → 3 days
    state = apply_sm2(state, quality=4)  # quality 4 = "good"
    assert state.interval_days == 3
    assert state.repetitions == 1

def test_incorrect_answer_resets():
    state = InitialReview()
    state = apply_sm2(state, quality=4)  # advance once
    state = apply_sm2(state, quality=0)  # forgotten
    assert state.interval_days == 1
    assert state.repetitions == 0
    assert state.ease < 2.5  # ease drops

def test_ease_floor():
    state = InitialReview()
    for _ in range(10):
        state = apply_sm2(state, quality=0)
    assert state.ease >= 1.3  # never below 1.3
