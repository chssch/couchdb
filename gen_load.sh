#! /bin/sh -e

TOTAL_DOCS=100000
BATCH_SIZE=500
CONCURRENCY=10
DELAYED_COMMITS=false
OPTIMISTIC=false
DB=load_test
HOST=localhost
PORT=5984

URL="http://$HOST:$PORT/_generate_load?total=$TOTAL_DOCS&db=$DB&concurrency=$CONCURRENCY&batch=$BATCH_SIZE&delayed_commits=$DELAYED_COMMITS&optimistic=$OPTIMISTIC"

DOC_ATTS='{"_attachments":{"foo.txt": {"content_type":"application/binary","data":"MTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx\r\nMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEx"}}}'

DOC_1K='{
    "category": "wizard",
    "type": "dwarf",
    "level": 13,
    "ratio": 1.8,
    "data1": "31d6aOtoEqmPOZH9wWnEP56LHRYq5LMkSbIzTzQk",
    "data2": "jQj9YEKLwLsvQnZdfp1Em1myn2cFtF6mp41UTHMSaz6ucLs0NN",
    "data3": "QxVx4VYQJ4kXamEuaNhZYMfJ9CRCGPVivox",
    "integers": [
        59740, 77318, 85730, 22711, 83219, 9113, 90262,
        10553, 69055, 62303, 67322, 63930, 20929, 77409
    ],
    "nested": {
        "dict": {
            "kZ3S3lrT": 64,
            "0QSA4KIy": 3983,
            "ViMej46m": 15688,
            "PCe8Fk8e": 7392,
            "9MbPSlq8": 129,
            "FpLOJP3C": 11758,
            "lETmhfOL": 66809
        },
        "string1": "UDurtwKrMJMB0r1TjCOGukB",
        "string2": "EBVZ8ETnsL71",
        "string3": "iKyrxEp6teTiazK6kH",
        "values": [
            58277, 88822, 77135, 3475, 40849, 77577,
            51913, 24551, 30071, 52972
        ],
        "coords": [
            {"x": 93424.85000000001, "y": 189872.72},
            {"x": 23527.94, "y": 155983.89},
            {"x": 2496.26, "y": 169499.21},
            {"x": 5681.62, "y": 40945.77},
            {"x": 67300.38, "y": 138137.1}
        ]
    }
}'

DOC_2K='{
    "data0": "9EVqHm5ARqcEB5jq21v2g0jVcG9CXB0Abk7uAF4NHYyTzeF3TnHhpZBECD14U2bCJPyBY0JWDr1Tjh8gTB0sWUNjqYiWDxFzlx6S",
    "data5": {
        "integers": [
            756509, 116117, 776378, 275045, 703447, 50156, 685803, 147958, 941747,
            905651, 57367, 530248, 312888, 740951, 988947, 450154
        ],
        "floats": [
            43121609.5543, 99454976.3019, 32945584.756, 18122905.9212, 14590614.6939,
            45292214.2242, 3332166.364, 53784167.729, 25193846.1867, 81456965.477,
            68532032.39, 73820009.7952, 57736110.5717, 37304166.7363, 20054244.864,
            29746392.7397, 86467624.6, 45192685.8793, 44008816.5186, 1861872.8736, 14595859.467,
            87795257.6703, 57768720.8303, 18290154.3126, 45893183.44, 63052200.6225, 69032152.6897,
            3748217.6946, 75449850.474, 37111527.415, 84852536.859, 32906366.487, 27027600.417,
            4758851.9417, 75227407.9214, 76946667.8403, 72518275.9469, 94167085.9588, 75883067.8321,
            27389831.6101, 57987075.5053, 1298995.2674
        ],
        "nested1": {
            "integers": [
                756509, 116117, 776378, 275045, 703447, 50156, 685803, 12345678,
                147958, 941747, 905651, 57367, 530248, 312888, 740951, 988947, 450154
            ],
            "floats": [
                41415831.8949, 24796297.4251, 2819085.3449, 84263963.4848, 74503228.6878, 67925677.403,
                4758851.9417, 75227407.9214, 76946667.8403, 72518275.9469, 94167085.9588, 75883067.8321,
                27389831.6101, 57987075.5053, 1298995.2674, 80858801.2712, 98262252.4656, 51612877.944,
                33397812.7835, 36089655.3049, 50164685.8153, 16852105.5192, 61171929.752, 86376339.7175
            ]
        }
    },
    "more_nested": {
        "nested2": {
            "strings": [
                "jURcBZ0vrJcmf2roZUMzZJQoTsKZDIdj7KhO7itskKvM80jBU9",
                "8jKLmo3N2zYdKyTyfTczfr2x6bPaarorlnTNJ7r8lIkiZyBvrP",
                "jbUeAVOdBSPzYmYhH0sabUHUH39O5e",
                "I8yAQKZsyZhMfpzWjArQU9pQ6PfU6b14q2eWvQjtCUdgAUxFjg",
                "97N8ZmGcxRZO4ZabzRRcY4KVHqxJwQ8qY",
                "0DtY1aWXmUfJENt9rYW9",
                "DtpBUEppPwMnWexi8eIIxlXRO3GUpPgeNFG9ONpWJYvk8xBkVj",
                "YsX8V2xOrTw6LhNIMMhO4F4VXFyXUXFr66L3sTkLWgFA9NZuBV",
                "fKYYthv8iFvaYoFoYZyB"
            ],
            "integers": [
                756509, 116117, 776378, 275045, 703447, 50156, 685803, 147958,
                941747, 905651, 57367, 530248, 312888, 740951, 988947, 450154
            ]
        }
    }
}'

curl -X POST \
        $URL \
	-H "Content-Type: application/json" \
	-d "$DOC_2K"
