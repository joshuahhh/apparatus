export default {
    "nodes":[
      {"id": "Rect", "name":"Rect","width":60,"height":60},
      {"id": "Rect-w", "name":"w","width":60,"height":60},
      {"id": "Rect-h", "name":"h","width":60,"height":60},
      {"id": "MyRect", "name":"MyRect","width":80,"height":60},
      {"id": "MyRect-w", "name":"w","width":60,"height":60},
      {"id": "MyRect-h", "name":"h","width":60,"height":60},
      {"id": 6, "name":"MyGroup","width":80,"height":60},
      {"id": 7, "name":"Group","width":70,"height":60},

      {"id": 8, "name":"MyRect","width":80,"height":60},
      {"id": 9, "name":"w","width":60,"height":60},
      {"id": 10, "name":"h","width":60,"height":60},
      {"id": 11, "name":"MyGroupV","width":100,"height":60},

      {"id": 12, "name":"MyCircle","width":80,"height":60},
      {"id": 13, "name":"Circle","width":80,"height":60},
      {"id": 14, "name":"MyCircle","width":80,"height":60},

      {"id": "Attribute", "name":"Attribute","width":90,"height":60}
    ],
    "links":[
      {"sourceId":"Rect-w","targetId":"Rect","type":"parent1"},
      {"sourceId":"Rect-h","targetId":"Rect","type":"parent2"},
      {"sourceId":"MyRect-w","targetId":"MyRect","type":"parent1"},
      {"sourceId":"MyRect-h","targetId":"MyRect","type":"parent2"},
      {"sourceId":"MyRect","targetId":"Rect","type":"master-head"},
      {"sourceId":"MyRect-w","targetId":"Rect-w","type":"master"},
      {"sourceId":"MyRect-h","targetId":"Rect-h","type":"master"},
      {"sourceId":"MyRect","targetId":6,"type":"parent2"},
      {"sourceId":6,"targetId":7,"type":"master-head"},
      {"sourceId":9,"targetId":8,"type":"parent1"},
      {"sourceId":10,"targetId":8,"type":"parent2"},
      {"sourceId":8,"targetId":11,"type":"parent2"},
      {"sourceId":11,"targetId":6,"type":"master-head"},
      {"sourceId":8,"targetId":"MyRect","type":"master"},
      {"sourceId":9,"targetId":"MyRect-w","type":"master"},
      {"sourceId":10,"targetId":"MyRect-h","type":"master"},
      {"sourceId":12,"targetId":6,"type":"parent1"},
      {"sourceId":12,"targetId":13,"type":"master-head"},
      {"sourceId":14,"targetId":11,"type":"parent1"},
      {"sourceId":14,"targetId":12,"type":"master"},
      {"sourceId":"Rect-w","targetId":"Attribute","type":"master-head"},
      {"sourceId":"Rect-h","targetId":"Attribute","type":"master-head"}

    ],
	"groups":[
    {"id":"Rect", "memberIds":["Rect","Rect-w","Rect-h"]},
    {"id":"MyRect", "memberIds":["MyRect","MyRect-w","MyRect-h"]},
    // {"id":2, "memberIds":[6]},
    {"id":"MyGroupV", "memberIds":[8,9,10,11,14]},
    // {"id":4, "memberIds":[12]}
	]
};
