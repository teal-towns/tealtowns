import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../app_scaffold.dart';

class About extends StatefulWidget {
  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<About> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String text = "# TealTowns \n\n" +
      "We believe the **loneliness and climate crises** can be solved by connecting people together to work on local green (nature based) projects. Specifically, to build TealTowns: **connected X-minute cities** where humans and nature thrive.\n\n" +
      "Our mission, charge and decision making framework is: **green your town with neighbors**. All team members are empowered to make any decision by asking: **Will this connect neighbors to reduce their carbon footprint?** If yes, do / support it. Otherwise, do not.\n\n" +
      "## How? \n\n" +
      "We use technology (**AI Urban Planner and 3D Visualizer**) and **local leaders** to make it easy for people to **meet their neighbors and green their city**, through both public and private (home improvement) projects.\n\n" +
      "We connect people and food hyper locally. We do this by adding in **soil boxes, community gardens, regenerative farms and Superblocks** to existing cities, and we design new cities where these are the default.\n\n" +
      "**Shared Ownership Superblocks** help neighbors co-purchase and co-own items and buy back their town, starting with **weekly Shared Meals** and building to purchases as large as homes and buildings as trust is built and the group grows.\n\n" +
      "## Values \n\n" +
      "Our values are: 1. Do the Right Thing, 2. Shine Bright, 3. Rising Tide Lifts All Boats, 4. Play!\n\n" +
      "## How We Work \n\n" +
      "We are a Teal (**self-organizing**, flat) organization where anyone can get involved and lead, whether they have 1 or 10+ hours per week to contribute. To get involved, **connect with your neighbors to start shared meals in your neighborhood**.\n\n" +
      "## Money \n\n" +
      "We are a non-profit, donation based organization of mostly local volunteers plus a paid team at \$30k, \$60k, \$90k, \$120k levels, with a goal to reduce cost of living so everyone can live happily on \$60k or less (with a transition phase of working quarter or part time as each person works toward that). It must be obvious to anyone that mission comes above money.\n\n" +
      "## Initiatives \n\n" +
      "We have 4 initiatives: 1. **Connect** (grow 100+ people local TealTowns teams doing local green projects), 2. **Own** (build a TealTowns local ownership (including housing) network to provide \$10,000 or less down payment housing and other co-purchases). 3. **Plan** (build an AI Urban Planner web / mobile product), 4. **Visualize** (build a 3D immersive experience of the plans).\n\n" +
      "## Focus \n\n" +
      "Our first focus is start the first 100 Shared Ownership Superblocks (100 to 150 neighbors each, connecting weekly for shared meals). Through that we will also trial and select our first 4 to 8 paid team members and generate revenue to pay them.\n\n" +
      "## More Info \n\n" +
      "See our blog for more details!\n\n" +
      "Contact us: team@tealtowns.org\n\n" + 
      "## Get Involved \n\n" +
      "Click **Events** and **Own** to post the first events and shared items in your neighborhood!\n\n";;
    return AppScaffoldComponent(
      body: ListView(
        children: [
          SizedBox(height: 30),
          MarkdownBody(
            selectable: true,
            data: text!,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              h1: Theme.of(context).textTheme.headline1,
              h2: Theme.of(context).textTheme.headline2,
              h3: Theme.of(context).textTheme.headline3,
              h4: Theme.of(context).textTheme.headline4,
              h5: Theme.of(context).textTheme.headline5,
              h6: Theme.of(context).textTheme.headline6,
            ),
          ),
          SizedBox(height: 30),
        ]
      )
    );
  }
}
