/// The habits.json written on first launch. Edit the file afterwards; the app never rewrites it.
public enum SeedConfig {
    public static func json(activeFrom: Day) -> String {
        """
        {
          "habits": [
            {
              "id": "weight",
              "name": "Weight",
              "type": "number",
              "unit": "kg",
              "decimals": 1,
              "trend": true,
              "prompt": "morning",
              "order": 10,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "sleep",
              "name": "Sleep",
              "description": "Bedtime last night and wake time this morning.",
              "type": "sleep",
              "unit": "h",
              "prompt": "morning",
              "order": 20,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "stretching",
              "name": "Stretching",
              "description": "The ~20 min morning stretching routine.",
              "type": "binary",
              "prompt": "morning",
              "order": 30,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "creatine",
              "name": "Creatine",
              "type": "binary",
              "prompt": "morning",
              "order": 40,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "pushups",
              "name": "Push-ups",
              "description": "Total reps across all sets today.",
              "type": "count",
              "unit": "reps",
              "min_target": 5,
              "prompt": "evening",
              "order": 10,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "squats",
              "name": "Squats",
              "description": "Total reps across all sets today.",
              "type": "count",
              "unit": "reps",
              "min_target": 5,
              "prompt": "evening",
              "order": 20,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "dead_hang",
              "name": "Dead hang",
              "description": "Best hold of the day, in seconds.",
              "type": "number",
              "unit": "s",
              "prompt": "evening",
              "order": 30,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "negatives",
              "name": "Negatives",
              "description": "Slow pull-up negatives (optional).",
              "type": "count",
              "unit": "reps",
              "prompt": "evening",
              "order": 40,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "applications",
              "name": "Applications",
              "description": "Job or PhD applications.",
              "type": "binary",
              "prompt": "evening",
              "order": 50,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "study",
              "name": "Study",
              "type": "binary",
              "prompt": "evening",
              "order": 60,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "read",
              "name": "Read",
              "type": "binary",
              "prompt": "evening",
              "order": 70,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "socializing",
              "name": "Socializing",
              "description": "Friends from India, friends here, or new people; girlfriend doesn't count.",
              "type": "binary",
              "tags": ["india", "here", "new people"],
              "prompt": "evening",
              "order": 80,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "german_course",
              "name": "German: course",
              "description": "20 min of the structured course.",
              "type": "binary",
              "prompt": "evening",
              "order": 90,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "german_vocab",
              "name": "German: flashcards",
              "description": "15 min of vocabulary flashcards.",
              "type": "binary",
              "prompt": "evening",
              "order": 100,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "german_listening",
              "name": "German: listening",
              "description": "15 min of German on YouTube.",
              "type": "binary",
              "prompt": "evening",
              "order": 110,
              "active_from": "\(activeFrom)"
            },
            {
              "id": "german_speaking",
              "name": "German: speaking",
              "description": "10 min of speaking aloud; shadowing (repeating audio after the speaker) counts.",
              "type": "binary",
              "prompt": "evening",
              "order": 120,
              "active_from": "\(activeFrom)"
            }
          ]
        }

        """
    }
}
