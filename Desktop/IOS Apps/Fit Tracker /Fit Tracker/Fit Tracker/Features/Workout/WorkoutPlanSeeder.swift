import Foundation

// MARK: - Workout Plan Seeder
// Pre-built workout plans for the app. Used as fallback if Firestore is unavailable.

struct WorkoutPlanSeeder {

    static let allPlans: [WorkoutPlan] = [fullBody3Day, pushPullLegs4Day, upperLower4Day, broSplit5Day, ppl6Day]

    // MARK: - 3-Day Full Body (Beginner)

    static let fullBody3Day = WorkoutPlan(
        id: "plan_fullbody_3day",
        name: "3-Day Full Body",
        description: "Perfect for beginners. Hits every muscle group 3x per week.",
        difficulty: .beginner,
        daysPerWeek: 3,
        isPremium: false,
        category: .fullBody,
        estimatedDurationMin: 45,
        days: [
            WorkoutDay(
                id: "fb3_dayA", dayNumber: 1, label: "Day A",
                muscleGroups: [.chest, .back, .legs],
                exercises: [
                    pe(id: "fb3_a1", exId: "ex_barbell_squat", name: "Barbell Squat", group: .legs, sets: 3, reps: "8-10", rest: 120, order: 1),
                    pe(id: "fb3_a2", exId: "ex_bench_press", name: "Bench Press", group: .chest, sets: 3, reps: "8-10", rest: 90, order: 2),
                    pe(id: "fb3_a3", exId: "ex_barbell_row", name: "Barbell Row", group: .back, sets: 3, reps: "8-10", rest: 90, order: 3),
                    pe(id: "fb3_a4", exId: "ex_ohp", name: "Overhead Press", group: .shoulders, sets: 3, reps: "8-12", rest: 90, order: 4),
                    pe(id: "fb3_a5", exId: "ex_plank", name: "Plank", group: .core, sets: 3, reps: "30-60s", rest: 60, order: 5),
                ]
            ),
            WorkoutDay(
                id: "fb3_dayB", dayNumber: 2, label: "Day B",
                muscleGroups: [.chest, .back, .legs],
                exercises: [
                    pe(id: "fb3_b1", exId: "ex_deadlift", name: "Deadlift", group: .back, sets: 3, reps: "5-8", rest: 180, order: 1),
                    pe(id: "fb3_b2", exId: "ex_incline_db", name: "Incline Dumbbell Press", group: .chest, sets: 3, reps: "10-12", rest: 90, order: 2),
                    pe(id: "fb3_b3", exId: "ex_lat_pulldown", name: "Lat Pulldown", group: .back, sets: 3, reps: "10-12", rest: 90, order: 3),
                    pe(id: "fb3_b4", exId: "ex_leg_press", name: "Leg Press", group: .legs, sets: 3, reps: "10-12", rest: 120, order: 4),
                    pe(id: "fb3_b5", exId: "ex_bicep_curl", name: "Bicep Curl", group: .arms, sets: 3, reps: "10-15", rest: 60, order: 5),
                ]
            ),
            WorkoutDay(
                id: "fb3_dayC", dayNumber: 3, label: "Day C",
                muscleGroups: [.chest, .back, .legs, .shoulders],
                exercises: [
                    pe(id: "fb3_c1", exId: "ex_front_squat", name: "Front Squat", group: .legs, sets: 3, reps: "8-10", rest: 120, order: 1),
                    pe(id: "fb3_c2", exId: "ex_db_bench", name: "Dumbbell Bench Press", group: .chest, sets: 3, reps: "10-12", rest: 90, order: 2),
                    pe(id: "fb3_c3", exId: "ex_cable_row", name: "Cable Row", group: .back, sets: 3, reps: "10-12", rest: 90, order: 3),
                    pe(id: "fb3_c4", exId: "ex_lateral_raise", name: "Lateral Raise", group: .shoulders, sets: 3, reps: "12-15", rest: 60, order: 4),
                    pe(id: "fb3_c5", exId: "ex_tricep_push", name: "Tricep Pushdown", group: .arms, sets: 3, reps: "10-15", rest: 60, order: 5),
                ]
            ),
        ],
        createdAt: Date()
    )

    // MARK: - 4-Day Push/Pull/Legs

    static let pushPullLegs4Day = WorkoutPlan(
        id: "plan_ppl_4day",
        name: "4-Day Push/Pull/Legs",
        description: "Intermediate split. Push and Pull days plus two leg days.",
        difficulty: .intermediate,
        daysPerWeek: 4,
        isPremium: false,
        category: .hypertrophy,
        estimatedDurationMin: 60,
        days: [
            WorkoutDay(
                id: "ppl4_push", dayNumber: 1, label: "Push Day",
                muscleGroups: [.chest, .shoulders, .arms],
                exercises: [
                    pe(id: "ppl_p1", exId: "ex_bench_press", name: "Bench Press", group: .chest, sets: 4, reps: "6-8", rest: 120, order: 1),
                    pe(id: "ppl_p2", exId: "ex_ohp", name: "Overhead Press", group: .shoulders, sets: 3, reps: "8-10", rest: 90, order: 2),
                    pe(id: "ppl_p3", exId: "ex_incline_db", name: "Incline Dumbbell Press", group: .chest, sets: 3, reps: "10-12", rest: 90, order: 3),
                    pe(id: "ppl_p4", exId: "ex_lateral_raise", name: "Lateral Raise", group: .shoulders, sets: 3, reps: "12-15", rest: 60, order: 4),
                    pe(id: "ppl_p5", exId: "ex_tricep_push", name: "Tricep Pushdown", group: .arms, sets: 3, reps: "10-15", rest: 60, order: 5),
                ]
            ),
            WorkoutDay(
                id: "ppl4_pull", dayNumber: 2, label: "Pull Day",
                muscleGroups: [.back, .arms],
                exercises: [
                    pe(id: "ppl_pl1", exId: "ex_deadlift", name: "Deadlift", group: .back, sets: 3, reps: "5-6", rest: 180, order: 1),
                    pe(id: "ppl_pl2", exId: "ex_lat_pulldown", name: "Lat Pulldown", group: .back, sets: 3, reps: "8-10", rest: 90, order: 2),
                    pe(id: "ppl_pl3", exId: "ex_cable_row", name: "Cable Row", group: .back, sets: 3, reps: "10-12", rest: 90, order: 3),
                    pe(id: "ppl_pl4", exId: "ex_face_pull", name: "Face Pull", group: .shoulders, sets: 3, reps: "15-20", rest: 60, order: 4),
                    pe(id: "ppl_pl5", exId: "ex_bicep_curl", name: "Bicep Curl", group: .arms, sets: 3, reps: "10-15", rest: 60, order: 5),
                ]
            ),
            WorkoutDay(
                id: "ppl4_legs1", dayNumber: 3, label: "Leg Day (Quad)",
                muscleGroups: [.legs, .core],
                exercises: [
                    pe(id: "ppl_l1", exId: "ex_barbell_squat", name: "Barbell Squat", group: .legs, sets: 4, reps: "6-8", rest: 150, order: 1),
                    pe(id: "ppl_l2", exId: "ex_leg_press", name: "Leg Press", group: .legs, sets: 3, reps: "10-12", rest: 120, order: 2),
                    pe(id: "ppl_l3", exId: "ex_leg_ext", name: "Leg Extension", group: .legs, sets: 3, reps: "12-15", rest: 60, order: 3),
                    pe(id: "ppl_l4", exId: "ex_calf_raise", name: "Calf Raise", group: .legs, sets: 4, reps: "12-15", rest: 60, order: 4),
                    pe(id: "ppl_l5", exId: "ex_plank", name: "Plank", group: .core, sets: 3, reps: "45-60s", rest: 60, order: 5),
                ]
            ),
            WorkoutDay(
                id: "ppl4_legs2", dayNumber: 4, label: "Leg Day (Posterior)",
                muscleGroups: [.legs],
                exercises: [
                    pe(id: "ppl_lp1", exId: "ex_rdl", name: "Romanian Deadlift", group: .legs, sets: 4, reps: "8-10", rest: 120, order: 1),
                    pe(id: "ppl_lp2", exId: "ex_hip_thrust", name: "Hip Thrust", group: .legs, sets: 3, reps: "10-12", rest: 90, order: 2),
                    pe(id: "ppl_lp3", exId: "ex_leg_curl", name: "Leg Curl", group: .legs, sets: 3, reps: "10-12", rest: 60, order: 3),
                    pe(id: "ppl_lp4", exId: "ex_walking_lunge", name: "Walking Lunge", group: .legs, sets: 3, reps: "12/leg", rest: 90, order: 4),
                    pe(id: "ppl_lp5", exId: "ex_calf_raise", name: "Seated Calf Raise", group: .legs, sets: 4, reps: "15-20", rest: 60, order: 5),
                ]
            ),
        ],
        createdAt: Date()
    )

    // MARK: - 4-Day Upper/Lower (Premium)

    static let upperLower4Day = WorkoutPlan(
        id: "plan_upper_lower_4day",
        name: "4-Day Upper/Lower",
        description: "Balanced split with 2 upper and 2 lower days. Great for strength & hypertrophy.",
        difficulty: .intermediate,
        daysPerWeek: 4,
        isPremium: true,
        category: .hypertrophy,
        estimatedDurationMin: 55,
        days: [
            WorkoutDay(
                id: "ul4_upper1", dayNumber: 1, label: "Upper A (Strength)",
                muscleGroups: [.chest, .back, .shoulders, .arms],
                exercises: [
                    pe(id: "ul_u1a", exId: "ex_bench_press", name: "Bench Press", group: .chest, sets: 4, reps: "5-6", rest: 150, order: 1),
                    pe(id: "ul_u1b", exId: "ex_barbell_row", name: "Barbell Row", group: .back, sets: 4, reps: "5-6", rest: 150, order: 2),
                    pe(id: "ul_u1c", exId: "ex_ohp", name: "Overhead Press", group: .shoulders, sets: 3, reps: "8-10", rest: 90, order: 3),
                    pe(id: "ul_u1d", exId: "ex_lat_pulldown", name: "Lat Pulldown", group: .back, sets: 3, reps: "10-12", rest: 90, order: 4),
                    pe(id: "ul_u1e", exId: "ex_bicep_curl", name: "Bicep Curl", group: .arms, sets: 3, reps: "10-15", rest: 60, order: 5),
                ]
            ),
            WorkoutDay(
                id: "ul4_lower1", dayNumber: 2, label: "Lower A (Strength)",
                muscleGroups: [.legs, .core],
                exercises: [
                    pe(id: "ul_l1a", exId: "ex_barbell_squat", name: "Barbell Squat", group: .legs, sets: 4, reps: "5-6", rest: 180, order: 1),
                    pe(id: "ul_l1b", exId: "ex_rdl", name: "Romanian Deadlift", group: .legs, sets: 3, reps: "8-10", rest: 120, order: 2),
                    pe(id: "ul_l1c", exId: "ex_leg_press", name: "Leg Press", group: .legs, sets: 3, reps: "10-12", rest: 120, order: 3),
                    pe(id: "ul_l1d", exId: "ex_calf_raise", name: "Calf Raise", group: .legs, sets: 4, reps: "12-15", rest: 60, order: 4),
                    pe(id: "ul_l1e", exId: "ex_plank", name: "Plank", group: .core, sets: 3, reps: "45-60s", rest: 60, order: 5),
                ]
            ),
            WorkoutDay(
                id: "ul4_upper2", dayNumber: 3, label: "Upper B (Hypertrophy)",
                muscleGroups: [.chest, .back, .shoulders, .arms],
                exercises: [
                    pe(id: "ul_u2a", exId: "ex_incline_db", name: "Incline Dumbbell Press", group: .chest, sets: 3, reps: "10-12", rest: 90, order: 1),
                    pe(id: "ul_u2b", exId: "ex_cable_row", name: "Cable Row", group: .back, sets: 3, reps: "10-12", rest: 90, order: 2),
                    pe(id: "ul_u2c", exId: "ex_lateral_raise", name: "Lateral Raise", group: .shoulders, sets: 3, reps: "12-15", rest: 60, order: 3),
                    pe(id: "ul_u2d", exId: "ex_face_pull", name: "Face Pull", group: .shoulders, sets: 3, reps: "15-20", rest: 60, order: 4),
                    pe(id: "ul_u2e", exId: "ex_tricep_push", name: "Tricep Pushdown", group: .arms, sets: 3, reps: "10-15", rest: 60, order: 5),
                ]
            ),
            WorkoutDay(
                id: "ul4_lower2", dayNumber: 4, label: "Lower B (Hypertrophy)",
                muscleGroups: [.legs],
                exercises: [
                    pe(id: "ul_l2a", exId: "ex_front_squat", name: "Front Squat", group: .legs, sets: 3, reps: "8-10", rest: 120, order: 1),
                    pe(id: "ul_l2b", exId: "ex_hip_thrust", name: "Hip Thrust", group: .legs, sets: 3, reps: "10-12", rest: 90, order: 2),
                    pe(id: "ul_l2c", exId: "ex_leg_curl", name: "Leg Curl", group: .legs, sets: 3, reps: "10-12", rest: 60, order: 3),
                    pe(id: "ul_l2d", exId: "ex_walking_lunge", name: "Walking Lunge", group: .legs, sets: 3, reps: "12/leg", rest: 90, order: 4),
                    pe(id: "ul_l2e", exId: "ex_calf_raise", name: "Seated Calf Raise", group: .legs, sets: 4, reps: "15-20", rest: 60, order: 5),
                ]
            ),
        ],
        createdAt: Date()
    )

    // MARK: - 5-Day Bro Split (Premium)

    static let broSplit5Day = WorkoutPlan(
        id: "plan_bro_split_5day",
        name: "5-Day Bro Split",
        description: "Classic bodybuilding split. One muscle group per day for maximum volume.",
        difficulty: .intermediate,
        daysPerWeek: 5,
        isPremium: true,
        category: .hypertrophy,
        estimatedDurationMin: 60,
        days: [
            WorkoutDay(
                id: "bro5_chest", dayNumber: 1, label: "Chest Day",
                muscleGroups: [.chest],
                exercises: [
                    pe(id: "bro_c1", exId: "ex_bench_press", name: "Bench Press", group: .chest, sets: 4, reps: "6-8", rest: 120, order: 1),
                    pe(id: "bro_c2", exId: "ex_incline_db", name: "Incline Dumbbell Press", group: .chest, sets: 3, reps: "8-10", rest: 90, order: 2),
                    pe(id: "bro_c3", exId: "ex_db_bench", name: "Dumbbell Flyes", group: .chest, sets: 3, reps: "10-12", rest: 60, order: 3),
                    pe(id: "bro_c4", exId: "ex_cable_row", name: "Cable Crossover", group: .chest, sets: 3, reps: "12-15", rest: 60, order: 4),
                ]
            ),
            WorkoutDay(
                id: "bro5_back", dayNumber: 2, label: "Back Day",
                muscleGroups: [.back],
                exercises: [
                    pe(id: "bro_b1", exId: "ex_deadlift", name: "Deadlift", group: .back, sets: 4, reps: "5-6", rest: 180, order: 1),
                    pe(id: "bro_b2", exId: "ex_lat_pulldown", name: "Lat Pulldown", group: .back, sets: 3, reps: "8-10", rest: 90, order: 2),
                    pe(id: "bro_b3", exId: "ex_barbell_row", name: "Barbell Row", group: .back, sets: 3, reps: "8-10", rest: 90, order: 3),
                    pe(id: "bro_b4", exId: "ex_cable_row", name: "Cable Row", group: .back, sets: 3, reps: "10-12", rest: 60, order: 4),
                ]
            ),
            WorkoutDay(
                id: "bro5_shoulders", dayNumber: 3, label: "Shoulder Day",
                muscleGroups: [.shoulders],
                exercises: [
                    pe(id: "bro_s1", exId: "ex_ohp", name: "Overhead Press", group: .shoulders, sets: 4, reps: "6-8", rest: 120, order: 1),
                    pe(id: "bro_s2", exId: "ex_lateral_raise", name: "Lateral Raise", group: .shoulders, sets: 4, reps: "12-15", rest: 60, order: 2),
                    pe(id: "bro_s3", exId: "ex_face_pull", name: "Face Pull", group: .shoulders, sets: 3, reps: "15-20", rest: 60, order: 3),
                    pe(id: "bro_s4", exId: "ex_lateral_raise", name: "Front Raise", group: .shoulders, sets: 3, reps: "12-15", rest: 60, order: 4),
                ]
            ),
            WorkoutDay(
                id: "bro5_legs", dayNumber: 4, label: "Leg Day",
                muscleGroups: [.legs],
                exercises: [
                    pe(id: "bro_lg1", exId: "ex_barbell_squat", name: "Barbell Squat", group: .legs, sets: 4, reps: "6-8", rest: 180, order: 1),
                    pe(id: "bro_lg2", exId: "ex_leg_press", name: "Leg Press", group: .legs, sets: 3, reps: "10-12", rest: 120, order: 2),
                    pe(id: "bro_lg3", exId: "ex_rdl", name: "Romanian Deadlift", group: .legs, sets: 3, reps: "8-10", rest: 120, order: 3),
                    pe(id: "bro_lg4", exId: "ex_leg_curl", name: "Leg Curl", group: .legs, sets: 3, reps: "10-12", rest: 60, order: 4),
                    pe(id: "bro_lg5", exId: "ex_calf_raise", name: "Calf Raise", group: .legs, sets: 4, reps: "12-15", rest: 60, order: 5),
                ]
            ),
            WorkoutDay(
                id: "bro5_arms", dayNumber: 5, label: "Arms Day",
                muscleGroups: [.arms],
                exercises: [
                    pe(id: "bro_a1", exId: "ex_bicep_curl", name: "Barbell Curl", group: .arms, sets: 4, reps: "8-10", rest: 90, order: 1),
                    pe(id: "bro_a2", exId: "ex_tricep_push", name: "Tricep Pushdown", group: .arms, sets: 4, reps: "8-10", rest: 90, order: 2),
                    pe(id: "bro_a3", exId: "ex_bicep_curl", name: "Hammer Curl", group: .arms, sets: 3, reps: "10-12", rest: 60, order: 3),
                    pe(id: "bro_a4", exId: "ex_tricep_push", name: "Overhead Extension", group: .arms, sets: 3, reps: "10-12", rest: 60, order: 4),
                ]
            ),
        ],
        createdAt: Date()
    )

    // MARK: - 6-Day PPL (Advanced/Premium)

    static let ppl6Day = WorkoutPlan(
        id: "plan_ppl_6day",
        name: "6-Day PPL",
        description: "Advanced program. Push/Pull/Legs twice per week for maximum growth.",
        difficulty: .advanced,
        daysPerWeek: 6,
        isPremium: true,
        category: .hypertrophy,
        estimatedDurationMin: 70,
        days: [
            WorkoutDay(
                id: "ppl6_push1", dayNumber: 1, label: "Push A",
                muscleGroups: [.chest, .shoulders, .arms],
                exercises: [
                    pe(id: "p6_p1a", exId: "ex_bench_press", name: "Bench Press", group: .chest, sets: 4, reps: "5-6", rest: 150, order: 1),
                    pe(id: "p6_p1b", exId: "ex_ohp", name: "Overhead Press", group: .shoulders, sets: 3, reps: "8-10", rest: 90, order: 2),
                    pe(id: "p6_p1c", exId: "ex_incline_db", name: "Incline Dumbbell Press", group: .chest, sets: 3, reps: "10-12", rest: 90, order: 3),
                    pe(id: "p6_p1d", exId: "ex_lateral_raise", name: "Lateral Raise", group: .shoulders, sets: 4, reps: "12-15", rest: 60, order: 4),
                    pe(id: "p6_p1e", exId: "ex_tricep_push", name: "Tricep Pushdown", group: .arms, sets: 3, reps: "10-15", rest: 60, order: 5),
                ]
            ),
            WorkoutDay(
                id: "ppl6_pull1", dayNumber: 2, label: "Pull A",
                muscleGroups: [.back, .arms],
                exercises: [
                    pe(id: "p6_pl1a", exId: "ex_deadlift", name: "Deadlift", group: .back, sets: 3, reps: "5-6", rest: 180, order: 1),
                    pe(id: "p6_pl1b", exId: "ex_lat_pulldown", name: "Lat Pulldown", group: .back, sets: 3, reps: "8-10", rest: 90, order: 2),
                    pe(id: "p6_pl1c", exId: "ex_cable_row", name: "Cable Row", group: .back, sets: 3, reps: "10-12", rest: 90, order: 3),
                    pe(id: "p6_pl1d", exId: "ex_face_pull", name: "Face Pull", group: .shoulders, sets: 3, reps: "15-20", rest: 60, order: 4),
                    pe(id: "p6_pl1e", exId: "ex_bicep_curl", name: "Bicep Curl", group: .arms, sets: 3, reps: "10-15", rest: 60, order: 5),
                ]
            ),
            WorkoutDay(
                id: "ppl6_legs1", dayNumber: 3, label: "Legs A",
                muscleGroups: [.legs],
                exercises: [
                    pe(id: "p6_l1a", exId: "ex_barbell_squat", name: "Barbell Squat", group: .legs, sets: 4, reps: "5-6", rest: 180, order: 1),
                    pe(id: "p6_l1b", exId: "ex_leg_press", name: "Leg Press", group: .legs, sets: 3, reps: "10-12", rest: 120, order: 2),
                    pe(id: "p6_l1c", exId: "ex_leg_curl", name: "Leg Curl", group: .legs, sets: 3, reps: "10-12", rest: 60, order: 3),
                    pe(id: "p6_l1d", exId: "ex_calf_raise", name: "Calf Raise", group: .legs, sets: 4, reps: "12-15", rest: 60, order: 4),
                ]
            ),
            WorkoutDay(
                id: "ppl6_push2", dayNumber: 4, label: "Push B",
                muscleGroups: [.chest, .shoulders, .arms],
                exercises: [
                    pe(id: "p6_p2a", exId: "ex_db_bench", name: "Dumbbell Bench Press", group: .chest, sets: 3, reps: "8-10", rest: 90, order: 1),
                    pe(id: "p6_p2b", exId: "ex_ohp", name: "Arnold Press", group: .shoulders, sets: 3, reps: "10-12", rest: 90, order: 2),
                    pe(id: "p6_p2c", exId: "ex_lateral_raise", name: "Cable Lateral Raise", group: .shoulders, sets: 3, reps: "12-15", rest: 60, order: 3),
                    pe(id: "p6_p2d", exId: "ex_tricep_push", name: "Overhead Tricep Extension", group: .arms, sets: 3, reps: "10-12", rest: 60, order: 4),
                ]
            ),
            WorkoutDay(
                id: "ppl6_pull2", dayNumber: 5, label: "Pull B",
                muscleGroups: [.back, .arms],
                exercises: [
                    pe(id: "p6_pl2a", exId: "ex_barbell_row", name: "Barbell Row", group: .back, sets: 4, reps: "6-8", rest: 120, order: 1),
                    pe(id: "p6_pl2b", exId: "ex_lat_pulldown", name: "Close Grip Pulldown", group: .back, sets: 3, reps: "10-12", rest: 90, order: 2),
                    pe(id: "p6_pl2c", exId: "ex_cable_row", name: "Single Arm Row", group: .back, sets: 3, reps: "10-12", rest: 60, order: 3),
                    pe(id: "p6_pl2d", exId: "ex_bicep_curl", name: "Hammer Curl", group: .arms, sets: 3, reps: "10-12", rest: 60, order: 4),
                ]
            ),
            WorkoutDay(
                id: "ppl6_legs2", dayNumber: 6, label: "Legs B",
                muscleGroups: [.legs],
                exercises: [
                    pe(id: "p6_l2a", exId: "ex_rdl", name: "Romanian Deadlift", group: .legs, sets: 4, reps: "8-10", rest: 120, order: 1),
                    pe(id: "p6_l2b", exId: "ex_hip_thrust", name: "Hip Thrust", group: .legs, sets: 3, reps: "10-12", rest: 90, order: 2),
                    pe(id: "p6_l2c", exId: "ex_walking_lunge", name: "Walking Lunge", group: .legs, sets: 3, reps: "12/leg", rest: 90, order: 3),
                    pe(id: "p6_l2d", exId: "ex_leg_ext", name: "Leg Extension", group: .legs, sets: 3, reps: "12-15", rest: 60, order: 4),
                ]
            ),
        ],
        createdAt: Date()
    )

    // MARK: - Helper

    private static func pe(id: String, exId: String, name: String, group: Exercise.MuscleGroup, sets: Int, reps: String, rest: Int, order: Int) -> PlanExercise {
        let libEx = WorkoutExerciseLibrary.allExercises.first(where: { $0.id == exId })
        return PlanExercise(
            id: id, exerciseId: exId, exerciseName: name, muscleGroup: group,
            sets: sets, repsRange: reps, restSeconds: rest, order: order,
            notes: nil, gifUrl: libEx?.gifUrl, instructions: libEx?.instructions
        )
    }
}
