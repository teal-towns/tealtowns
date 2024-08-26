import 'package:flutter/material.dart';

import '../../common/colors_service.dart';
import '../../common/layout_service.dart';
import '../../common/style.dart';
import '../../app_scaffold.dart';

class AIUrbanPlannerAbout extends StatefulWidget {
  @override
  _AIUrbanPlannerAboutState createState() => _AIUrbanPlannerAboutState();
}

class _AIUrbanPlannerAboutState extends State<AIUrbanPlannerAbout> {
  ColorsService _colors = ColorsService();
  LayoutService _layoutService = LayoutService();
  Style _style = Style();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> problems = [
      { 'title': 'EXCESSIVE HEAT', 'details': 'Life-threatening heat and humidity are expected to impact between half to three-fourths of the global population by 2100', },
      { 'title': 'FLOODING', 'details': '1.81 billion people face significant flood risk worldwide', },
      { 'title': 'FOOD INSECURITY', 'details': 'Food security will be increasingly affected by projected future climate change', },
      { 'title': 'AIR POLLUTION', 'details': 'Air pollution is the world\'s leading environmental cause of illness and premature death', },
      { 'title': 'BIODIVERSITY LOSS', 'details': 'One million species face extinction. These losses—accompanied by the destruction of forests and other ecosystems—prevent carbon storage, accelerate climate change', },
      { 'title': 'SOCIAL ISOLATION', 'details': 'Loneliness has been declared an epidemic in the US and remain a public health concern around the world', },
    ];
    List<Widget> itemsProblems = [];
    for (var item in problems) {
      itemsProblems += [
        Container(
          color: _colors.colors['white'],
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _style.Text1(item['title'], size: 'large', colorKey: 'primary'),
              _style.SpacingH('medium'),
              _style.Text1(item['details']),
            ],
          )
        )
      ];
    }

    List<Map<String, dynamic>> solutions = [
      { 'title': 'Computer Vision and Satellite Imagery Analysis', 'details': 'This will allow us to identify underutilized spaces in urban areas, prioritize regions with excessive heat and flood risks, and suggest appropriate solutions to reduce temperature and increase permeability', },
      { 'title': 'Recommendation Algorithms', 'details': 'These will be used to propose specific solutions - planting for food, biodiversity, and cooling, water bioretention and rain gardens, microforests - that align with community needs and environmental conditions.', },
      { 'title': 'AI Simulation Tools', 'details': 'These tools will help visualize the effectiveness of anti-flooding measures, such as swales or rain gardens, by analyzing factors like sun exposure, wind patterns, soil quality, and flood risk. The AI will also guide users through the implementation process, from identifying required permits to estimating costs', },
    ];
    List<Widget> itemsSolutions = [];
    for (var item in solutions) {
      itemsSolutions += [
        Container(
          color: _colors.colors['white'],
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _style.Text1(item['title'], size: 'large', colorKey: 'primary'),
              _style.SpacingH('medium'),
              _style.Text1(item['details']),
            ],
          )
        ),
      ];
    }

    double height = 450;
    double maxWidth = 1100;
    return AppScaffoldComponent(
      listWrapper: true,
      width: double.infinity,
      body: Column(
        children: [
          Container(
            constraints: BoxConstraints(minHeight: height),
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/ai_urban_planner/world.png"),
                fit: BoxFit.cover,
                // colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.9), BlendMode.dstATop),
              ),
            ),
            child: Column(
              children: [
                _style.SpacingH('xlarge'),
                _style.Text1('The Problem', size: 'xxlarge'),
                _style.SpacingH('xlarge'),
                Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(flex: 1, child: Container()),
                          _style.Text1('56%', size: 'xxlarge', colorKey: 'primary'),
                          SizedBox(width: 30),
                          Expanded(flex: 2, child: _style.Text1('OF THE WORLD\'S POPULATION LIVES IN CITIES', size: 'large')),
                          Expanded(flex: 1, child: Container()),
                        ],
                      ),
                      _style.SpacingH('xlarge'),
                      Row(
                        children: [
                          Expanded(flex: 1, child: Container()),
                          _style.Text1('75%', size: 'xxlarge', colorKey: 'primary'),
                          SizedBox(width: 30),
                          Expanded(flex: 2, child: _style.Text1('OF THE WORLD\'S CO2 EMISSIONS COME FROM CITIES', size: 'large')),
                          Expanded(flex: 1, child: Container()),
                        ],
                      ),
                    ],
                  ),
                ),
                _style.SpacingH('xlarge'),
              ],
            )
          ),
          Container(
            constraints: BoxConstraints(minHeight: height),
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/ai_urban_planner/dry-cracked-earth.jpg"),
                fit: BoxFit.cover,
                // colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.dstATop),
              ),
            ),
            child: Column(
              children: [
                _style.SpacingH('xlarge'),
                Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: _layoutService.WrapWidth(itemsProblems, width: 300,),
                ),
                _style.SpacingH('xlarge'),
              ]
            ),
          ),
          Container(
            constraints: BoxConstraints(minHeight: height, maxWidth: maxWidth),
            width: double.infinity,
            child: BuildSolution1(context),
          ),
          Container(
            constraints: BoxConstraints(minHeight: height),
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/ai_urban_planner/world.png"),
                fit: BoxFit.cover,
                // colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.dstATop),
              ),
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: [
                  _style.SpacingH('xlarge'),
                  _style.Text1('Our Solution', size: 'xxlarge'),
                  _style.SpacingH('large'),
                  _layoutService.WrapWidth(itemsSolutions),
                  _style.SpacingH('xlarge'),
                ],
              ),
            )
          ),
        ]
      )
    );
  }

  Widget BuildSolution1(BuildContext context) {
    Widget logoContent = Column(
      children: [
        Image.asset('assets/images/ai_urban_planner/green-world.png', width: 100, height: 100),
        Container(
          constraints: BoxConstraints(maxWidth: 300),
          child: _style.Text1('AI Sustainable Urban Planner', size: 'xxlarge', align: 'center',),
        ),
      ],
    );

    Widget rightContent = Column(
      children: [
        Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: _colors.colors['greyLighter'],
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _style.Text1('OUR VISION', colorKey: 'primary', size: 'large',),
                    _style.SpacingH('medium'),
                    _style.Text1('Empowered Communities, Greener Cities', size: 'large'),
                    _style.SpacingH('medium'),
                  ],
                ),
              ),
            ],
          )
        ),
        _style.SpacingH('large'),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: _colors.colors['primary'], width: 3),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _style.Text1('Imagine a city where every resident has the tools to shape their environment—where sustainability is driven by community action, supported by advanced AI technology. Our vision is to make this a reality.', size: 'large'),
              _style.SpacingH('medium'),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return Row(
            children: [
              Expanded(flex: 1,
                child: logoContent,
              ),
              Expanded(flex: 1, child: Column(
                children: [
                  _style.SpacingH('large'),
                  rightContent,
                  _style.SpacingH('medium'),
                ]
              )),
            ],
          );
        } else {
          return Column(
            children: [
              _style.SpacingH('large'),
              logoContent,
              _style.SpacingH('large'),
              rightContent,
              _style.SpacingH('large'),
            ],
          );
        }
      }
    );
  }
}
