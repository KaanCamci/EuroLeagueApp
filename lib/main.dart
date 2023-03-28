import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'package:html/parser.dart' as parser;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Container> containerList = [];
  bool isOperationsFinished = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Timer.run(() => printSelected());
  }


  Future<void> saveData(Map<String, dynamic> jsonFormat, String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, json.encode(jsonFormat));
  }

  Future<Map<String, dynamic>> loadData(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var jsonFormat = prefs.getString(key);
    return json.decode(jsonFormat!);
  }

  Future<bool> isKeyExist(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  Future<void> printSchedule() async {
    isOperationsFinished = false;
    var url = Uri.parse("https://www.flashscore.com/basketball/europe/euroleague/fixtures/");
    await Future.delayed(const Duration(seconds: 2)); // 2 saniye bekleyin
    var res = await http.get(url);
    await Future.delayed(const Duration(seconds: 2)); // 2 saniye bekleyin
    var body = res.body;
    await Future.delayed(const Duration(seconds: 2)); // 2 saniye bekleyin
    var document = parser.parse(body);
    List<String> dates = [];
    await Future.delayed(const Duration(seconds: 2)); // 2 saniye bekleyin

    log(document.getElementsByClassName("event__time")[0].text.toString());

    isOperationsFinished = true;
  }




  //printing match scores due to selected team and season
  Future<void> printSelected() async {
    //not controlled (the aim of this part is: if the season is 2022 and there is no json file of a match between 208th and 330th,
    // and if the match played or being played(info in api) it controls api of that match and if there is info of that match, it creates a json file for that
    // match. if there is no info of that match in api, this part breaks; because there will be no match further.)

    isOperationsFinished = false;
    if (selectedSeason.contains("2022")) {
      for (int i = 208; i < 330; i++) {
        //208 = 702306
        if (!(await isKeyExist((i + 6).toString()))) {
          // dosya yoksa yapılacak işlemler

          int matchIDOfWebsite = i + 702098;
          var url = Uri.parse(
              "https://www.proballers.com/basketball/game/$matchIDOfWebsite");
          var res = await http.get(url);
          var body = res.body;
          var document = parser.parse(body);

          //arka arkaya 2 maç sonucu yoksa verileri else kısmında almak(2 kere kontrol etme amacı ertelenen maçların process'i durdurmaması)(arka arkaya 2 maç ertelenmişse yeni veri alınmaz)
          if (!document
              .getElementsByClassName(
                  "home-game__content__result__final-score__score")[0]
              .getElementsByClassName("score")
              .isNotEmpty) {
            int matchIDOfWebsite1 = i + 702099;
            var url1 = Uri.parse(
                "https://www.proballers.com/basketball/game/$matchIDOfWebsite1");
            var res1 = await http.get(url1);
            var body1 = res1.body;
            var document1 = parser.parse(body1);

            if (!document1
                .getElementsByClassName(
                    "home-game__content__result__final-score__score")[0]
                .getElementsByClassName("score")
                .isNotEmpty) {
              break;
            }
          } else {
            List<String> names = [];
            document.getElementsByClassName("team-name").forEach((element) {
              names.add(element.text);
            });
            List<String> scores = document
                .getElementsByClassName(
                    "home-game__content__result__final-score__score")[0]
                .getElementsByClassName("score")[0]
                .text
                .split(" - ");

            List<String> playerNamesOfFirstTeam = [];
            document
                .getElementsByClassName("table")[0]
                .getElementsByClassName("list-player-entry")
                .forEach((element) {
              if (element.attributes['title'] != null) {
                playerNamesOfFirstTeam
                    .add(element.attributes['title'].toString());
              }
            });

            List<String> playerNamesOfSecondTeam = [];
            document
                .getElementsByClassName("table")[1]
                .getElementsByClassName("list-player-entry")
                .forEach((element) {
              if (element.attributes['title'] != null) {
                playerNamesOfSecondTeam
                    .add(element.attributes['title'].toString());
              }
            });

            List<String> firstTeamStats = [];
            List<String> secondTeamStats = [];

            var tableFootElementsOne = document
                .getElementsByClassName("table")[0]
                .getElementsByTagName("tfoot")[0]
                .getElementsByTagName("tr"); //satırları tutuyor
            for (int i = 0; i < tableFootElementsOne.length; i++) {
              //satırlarda dolaşıyor
              var trElementOne = tableFootElementsOne[i];
              trElementOne.getElementsByClassName("strong").forEach((element) {
                //satırın içinde dolaşıyor
                if (!element.classes.contains("left")) {
                  firstTeamStats.add(element.text);
                }
              });
            }
            var tableFootElementsTwo = document
                .getElementsByClassName("table")[1]
                .getElementsByTagName("tfoot")[0]
                .getElementsByTagName("tr"); //satırları tutuyor
            for (int i = 0; i < tableFootElementsTwo.length; i++) {
              //satırlarda dolaşıyor
              var trElementTwo = tableFootElementsTwo[i];
              trElementTwo.getElementsByClassName("strong").forEach((element) {
                //satırın içinde dolaşıyor
                if (!element.classes.contains("left")) {
                  secondTeamStats.add(element.text);
                }
              });
            }

            List<String> pointsOfPlayersOfFirstTeam = [];
            List<String> offensiveReboundsOfPlayersOfFirstTeam = [];
            List<String> defensiveReboundsOfPlayersOfFirstTeam = [];
            List<String> reboundsOfPlayersOfFirstTeam = [];
            List<String> assistsOfPlayersOfFirstTeam = [];
            List<String> minutesOfPlayersOfFirstTeam = [];
            List<String> twoPointsOfPlayersOfFirstTeam = [];
            List<String> twoPointsAttemptedOfPlayersOfFirstTeam = [];
            List<String> threePointsOfPlayersOfFirstTeam = [];
            List<String> threePointsAttemptedOfPlayersOfFirstTeam = [];
            List<String> freeThrowsOfPlayersOfFirstTeam = [];
            List<String> freeThrowsAttemptedOfPlayersOfFirstTeam = [];
            List<String> turnoversOfPlayersOfFirstTeam = [];
            List<String> stealsOfPlayersOfFirstTeam = [];
            List<String> blocksOfPlayersOfFirstTeam = [];
            List<String> foulsOfPlayersOfFirstTeam = [];
            List<String> efficiencyOfPlayersOfFirstTeam = [];

            var tableElements = document
                .getElementsByClassName("table")[0]
                .getElementsByTagName("tbody")[0]
                .getElementsByTagName("tr"); //satırları tutuyor
            for (int i = 0; i < tableElements.length; i++) {
              //satırlarda dolaşıyor
              var trElement = tableElements[i]; //bir satır
              List<String> dataOfTableFirst =
                  []; //satırın içindeki verileri tutacak liste
              trElement.getElementsByClassName("right").forEach((element) {
                //satırın içinde dolaşıyor
                dataOfTableFirst
                    .add(element.text); //satırın içindeki verileri yazıyor
              });
              pointsOfPlayersOfFirstTeam.add(dataOfTableFirst[0]);
              offensiveReboundsOfPlayersOfFirstTeam.add(dataOfTableFirst[9]);
              defensiveReboundsOfPlayersOfFirstTeam.add(dataOfTableFirst[10]);
              reboundsOfPlayersOfFirstTeam.add(dataOfTableFirst[1]);
              assistsOfPlayersOfFirstTeam.add(dataOfTableFirst[2]);
              minutesOfPlayersOfFirstTeam.add(dataOfTableFirst[3]);
              twoPointsOfPlayersOfFirstTeam
                  .add(dataOfTableFirst[4].split("-")[0]);
              twoPointsAttemptedOfPlayersOfFirstTeam
                  .add(dataOfTableFirst[4].split("-")[1]);
              threePointsOfPlayersOfFirstTeam
                  .add(dataOfTableFirst[5].split("-")[0]);
              threePointsAttemptedOfPlayersOfFirstTeam
                  .add(dataOfTableFirst[5].split("-")[1]);
              freeThrowsOfPlayersOfFirstTeam
                  .add(dataOfTableFirst[7].split("-")[0]);
              freeThrowsAttemptedOfPlayersOfFirstTeam
                  .add(dataOfTableFirst[7].split("-")[1]);
              turnoversOfPlayersOfFirstTeam.add(dataOfTableFirst[13]);
              stealsOfPlayersOfFirstTeam.add(dataOfTableFirst[14]);
              blocksOfPlayersOfFirstTeam.add(dataOfTableFirst[15]);
              foulsOfPlayersOfFirstTeam.add(dataOfTableFirst[16]);
              efficiencyOfPlayersOfFirstTeam.add(dataOfTableFirst[18]);
            }

            List<String> pointsOfPlayersOfSecondTeam = [];
            List<String> offensiveReboundsOfPlayersOfSecondTeam = [];
            List<String> defensiveReboundsOfPlayersOfSecondTeam = [];
            List<String> reboundsOfPlayersOfSecondTeam = [];
            List<String> assistsOfPlayersOfSecondTeam = [];
            List<String> minutesOfPlayersOfSecondTeam = [];
            List<String> twoPointsOfPlayersOfSecondTeam = [];
            List<String> twoPointsAttemptedOfPlayersOfSecondTeam = [];
            List<String> threePointsOfPlayersOfSecondTeam = [];
            List<String> threePointsAttemptedOfPlayersOfSecondTeam = [];
            List<String> freeThrowsOfPlayersOfSecondTeam = [];
            List<String> freeThrowsAttemptedOfPlayersOfSecondTeam = [];
            List<String> turnoversOfPlayersOfSecondTeam = [];
            List<String> stealsOfPlayersOfSecondTeam = [];
            List<String> blocksOfPlayersOfSecondTeam = [];
            List<String> foulsOfPlayersOfSecondTeam = [];
            List<String> efficiencyOfPlayersOfSecondTeam = [];

            var tableElementsSecond = document
                .getElementsByClassName("table")[1]
                .getElementsByTagName("tbody")[0]
                .getElementsByTagName("tr"); //satırları tutuyor
            for (int i = 0; i < tableElementsSecond.length; i++) {
              //satırlarda dolaşıyor
              var trElementSecond = tableElementsSecond[i]; //bir satır
              List<String> dataOfTableFirst =
                  []; //satırın içindeki verileri tutacak liste
              trElementSecond
                  .getElementsByClassName("right")
                  .forEach((element) {
                //satırın içinde dolaşıyor
                dataOfTableFirst
                    .add(element.text); //satırın içindeki verileri yazıyor
              });
              pointsOfPlayersOfSecondTeam.add(dataOfTableFirst[0]);
              offensiveReboundsOfPlayersOfSecondTeam.add(dataOfTableFirst[9]);
              defensiveReboundsOfPlayersOfSecondTeam.add(dataOfTableFirst[10]);
              reboundsOfPlayersOfSecondTeam.add(dataOfTableFirst[1]);
              assistsOfPlayersOfSecondTeam.add(dataOfTableFirst[2]);
              minutesOfPlayersOfSecondTeam.add(dataOfTableFirst[3]);
              twoPointsOfPlayersOfSecondTeam
                  .add(dataOfTableFirst[4].split("-")[0]);
              twoPointsAttemptedOfPlayersOfSecondTeam
                  .add(dataOfTableFirst[4].split("-")[1]);
              threePointsOfPlayersOfSecondTeam
                  .add(dataOfTableFirst[5].split("-")[0]);
              threePointsAttemptedOfPlayersOfSecondTeam
                  .add(dataOfTableFirst[5].split("-")[1]);
              freeThrowsOfPlayersOfSecondTeam
                  .add(dataOfTableFirst[7].split("-")[0]);
              freeThrowsAttemptedOfPlayersOfSecondTeam
                  .add(dataOfTableFirst[7].split("-")[1]);
              turnoversOfPlayersOfSecondTeam.add(dataOfTableFirst[13]);
              stealsOfPlayersOfSecondTeam.add(dataOfTableFirst[14]);
              blocksOfPlayersOfSecondTeam.add(dataOfTableFirst[15]);
              foulsOfPlayersOfSecondTeam.add(dataOfTableFirst[16]);
              efficiencyOfPlayersOfSecondTeam.add(dataOfTableFirst[18]);
            }

            Map<String, dynamic> jsonFormat = {
              "EndOfQuarter": [
                {"Team": names[0], "Quarter4": scores[0]},
                {"Team": names[1], "Quarter4": scores[1]}
              ],
              "Stats": [
                {"Team": names[0], "PlayersStats": [], "totr": {}},
                {"Team": names[1], "PlayersStats": [], "totr": {}}
              ]
            };

            for (int x = 0; x < playerNamesOfFirstTeam.length; x++) {
              jsonFormat["Stats"][0]["PlayersStats"].add({
                "Player": playerNamesOfFirstTeam[x],
                "Minutes": minutesOfPlayersOfFirstTeam[x],
                "Points": pointsOfPlayersOfFirstTeam[x],
                "FieldGoalsMade2": twoPointsOfPlayersOfFirstTeam[x],
                "FieldGoalsAttempted2":
                    twoPointsAttemptedOfPlayersOfFirstTeam[x],
                "FieldGoalsMade3": threePointsOfPlayersOfFirstTeam[x],
                "FieldGoalsAttempted3":
                    threePointsAttemptedOfPlayersOfFirstTeam[x],
                "FreeThrowsMade": freeThrowsOfPlayersOfFirstTeam[x],
                "FreeThrowsAttempted":
                    freeThrowsAttemptedOfPlayersOfFirstTeam[x],
                "OffensiveRebounds": offensiveReboundsOfPlayersOfFirstTeam[x],
                "DefensiveRebounds": defensiveReboundsOfPlayersOfFirstTeam[x],
                "TotalRebounds": reboundsOfPlayersOfFirstTeam[x],
                "Assistances": assistsOfPlayersOfFirstTeam[x],
                "Steals": stealsOfPlayersOfFirstTeam[x],
                "Turnovers": turnoversOfPlayersOfFirstTeam[x],
                "BlocksFavour": blocksOfPlayersOfFirstTeam[x],
                "FoulsCommited": foulsOfPlayersOfFirstTeam[x],
                "Valuation": efficiencyOfPlayersOfFirstTeam[x]
              });
            }

            for (int x = 0; x < playerNamesOfSecondTeam.length; x++) {
              jsonFormat["Stats"][1]["PlayersStats"].add({
                "Player": playerNamesOfSecondTeam[x],
                "Minutes": minutesOfPlayersOfSecondTeam[x],
                "Points": pointsOfPlayersOfSecondTeam[x],
                "FieldGoalsMade2": twoPointsOfPlayersOfSecondTeam[x],
                "FieldGoalsAttempted2":
                    twoPointsAttemptedOfPlayersOfSecondTeam[x],
                "FieldGoalsMade3": threePointsOfPlayersOfSecondTeam[x],
                "FieldGoalsAttempted3":
                    threePointsAttemptedOfPlayersOfSecondTeam[x],
                "FreeThrowsMade": freeThrowsOfPlayersOfSecondTeam[x],
                "FreeThrowsAttempted":
                    freeThrowsAttemptedOfPlayersOfSecondTeam[x],
                "OffensiveRebounds": offensiveReboundsOfPlayersOfSecondTeam[x],
                "DefensiveRebounds": defensiveReboundsOfPlayersOfSecondTeam[x],
                "TotalRebounds": reboundsOfPlayersOfSecondTeam[x],
                "Assistances": assistsOfPlayersOfSecondTeam[x],
                "Steals": stealsOfPlayersOfSecondTeam[x],
                "Turnovers": turnoversOfPlayersOfSecondTeam[x],
                "BlocksFavour": blocksOfPlayersOfSecondTeam[x],
                "FoulsCommited": foulsOfPlayersOfSecondTeam[x],
                "Valuation": efficiencyOfPlayersOfSecondTeam[x]
              });
            }

            jsonFormat["Stats"][0]["totr"] = {
              "Points": firstTeamStats[0],
              "FieldGoalsMade2": firstTeamStats[4].split("-")[0],
              "FieldGoalsAttempted2": firstTeamStats[4].split("-")[1],
              "FieldGoalsMade3": firstTeamStats[5].split("-")[0],
              "FieldGoalsAttempted3": firstTeamStats[5].split("-")[1],
              "FreeThrowsMade": firstTeamStats[7].split("-")[0],
              "FreeThrowsAttempted": firstTeamStats[7].split("-")[1],
              "OffensiveRebounds": firstTeamStats[9],
              "DefensiveRebounds": firstTeamStats[10],
              "TotalRebounds": firstTeamStats[11],
              "Assistances": firstTeamStats[12],
              "Steals": firstTeamStats[14],
              "Turnovers": firstTeamStats[13],
              "BlocksFavour": firstTeamStats[15],
              "FoulsCommited": firstTeamStats[16],
              "Valuation": firstTeamStats[18],
            };

            jsonFormat["Stats"][1]["totr"] = {
              "Points": secondTeamStats[0],
              "FieldGoalsMade2": secondTeamStats[4].split("-")[0],
              "FieldGoalsAttempted2": secondTeamStats[4].split("-")[1],
              "FieldGoalsMade3": secondTeamStats[5].split("-")[0],
              "FieldGoalsAttempted3": secondTeamStats[5].split("-")[1],
              "FreeThrowsMade": secondTeamStats[7].split("-")[0],
              "FreeThrowsAttempted": secondTeamStats[7].split("-")[1],
              "OffensiveRebounds": secondTeamStats[9],
              "DefensiveRebounds": secondTeamStats[10],
              "TotalRebounds": secondTeamStats[11],
              "Assistances": secondTeamStats[12],
              "Steals": secondTeamStats[14],
              "Turnovers": secondTeamStats[13],
              "BlocksFavour": secondTeamStats[15],
              "FoulsCommited": secondTeamStats[16],
              "Valuation": secondTeamStats[18],
            };
            saveData(jsonFormat, i.toString());
          }
        }
      }
    }

    //gets data from json files and prints them on the screen
    var jsonData;
    for (int i = 330; i > 0; i--) {
      if (selectedSeason.contains("2022")) {
        if (await isKeyExist(i.toString())) {
          var loadedData = await loadData(i.toString());
          jsonData = loadedData;
        } else {
          try {
            var response = await rootBundle.loadString(
                'assets/JsonFolder/$selectedSeason/gamecode=$i&seasoncode=E$selectedSeason.json');
            jsonData = json.decode(response);
          } catch (e) {
            continue;
          }
        }
      } else {
        try {
          var response = await rootBundle.loadString(
              'assets/JsonFolder/$selectedSeason/gamecode=$i&seasoncode=E$selectedSeason.json');
          jsonData = json.decode(response);
        } catch (e) {
          continue;
        }
      }

      String team1 = jsonData["EndOfQuarter"][0]["Team"];
      String team2 = jsonData["EndOfQuarter"][1]["Team"];
      int score1;
      int score2;
      if (jsonData.containsKey("ByQuarter")) {
        if (jsonData["ByQuarter"][0].containsKey("Extra1")) {
          score1 = jsonData["EndOfQuarter"][0]["Extra1"];
          score2 = jsonData["EndOfQuarter"][1]["Extra1"];
        } else {
          score1 = jsonData["EndOfQuarter"][0]["Quarter4"];
          score2 = jsonData["EndOfQuarter"][1]["Quarter4"];
        }
      } else {
        score1 = int.parse(jsonData["EndOfQuarter"][0]["Quarter4"]);
        score2 = int.parse(jsonData["EndOfQuarter"][1]["Quarter4"]);
      }

      team1 = team1.toUpperCase();
      team2 = team2.toUpperCase();
      if (selectedTeam.toUpperCase() == team1 ||
          selectedTeam.toUpperCase() == team2 ||
          selectedTeam == "Hepsi") {
        var team1Input;
        var team2Input;
        var score1Input = score1;
        var score2Input = score2;

        if (team1.contains("EFES")) {
          team1Input = "efes";
        } else if (team1.contains("BASKONIA") || team1.contains("CERAMICA")) {
          team1Input = "baskonia";
        } else if (team1.contains("PANATHINAIKOS")) {
          team1Input = "panat";
        } else if (team1.contains("ASVEL")) {
          team1Input = "asvel";
        } else if (team1.contains("BOLOGNA")) {
          team1Input = "bologna";
        } else if (team1.contains("OLYMPIACOS")) {
          team1Input = "olympiacos";
        } else if (team1.contains("ZALGIRIS")) {
          team1Input = "zalgiris";
        } else if (team1.contains("PARTIZAN")) {
          team1Input = "partizan";
        } else if (team1.contains("MONACO")) {
          team1Input = "monaco";
        } else if (team1.contains("MADRID")) {
          team1Input = "real";
        } else if (team1.contains("FENERBAHCE") || team1.contains("FB DOGUS")) {
          team1Input = "fener";
        } else if (team1.contains("ALBA")) {
          team1Input = "alba";
        } else if (team1.contains("VALENCIA")) {
          team1Input = "valencia";
        } else if (team1.contains("MACCABI")) {
          team1Input = "maccabi";
        } else if (team1.contains("MILAN")) {
          team1Input = "milano";
        } else if (team1.contains("CRVENA")) {
          team1Input = "crvena";
        } else if (team1.contains("BARCELONA")) {
          team1Input = "barcelona";
        } else if (team1.contains("BAYERN")) {
          team1Input = "munich";
        } else if (team1.contains("ZENIT")) {
          team1Input = "zenit";
        } else if (team1.contains("UNICS")) {
          team1Input = "unics";
        } else if (team1.contains("CSKA")) {
          team1Input = "cska";
        } else if (team1.contains("KHIMKI")) {
          team1Input = "khimki";
        } else if (team1.contains("BUDUCNOST")) {
          team1Input = "buducnost";
        } else if (team1.contains("CANARIA")) {
          team1Input = "canaria";
        } else if (team1.contains("DARUSSAFAKA")) {
          team1Input = "darussafaka";
        } else if (team1.contains("UNICAJA") || team1.contains("BALONCESTO")) {
          team1Input = "unicaja";
        } else if (team1.contains("GALATASARAY")) {
          team1Input = "galatasaray";
        } else if (team1.contains("BROSE") || team1.contains("BAMBERG")) {
          team1Input = "brose";
        } else if (team1.contains("STRASBOURG")) {
          team1Input = "strasbourg";
        } else if (team1.contains("LABORAL")) {
          team1Input = "baskonia";
        } else if (team1.contains("ZAGREB")) {
          team1Input = "cedevita";
        } else if (team1.contains("LIMOGES")) {
          team1Input = "limoges";
        } else if (team1.contains("ZIELONA")) {
          team1Input = "zielona";
        } else if (team1.contains("KUBAN")) {
          team1Input = "kuban";
        } else if (team1.contains("KARSIYAKA")) {
          team1Input = "karsiyaka";
        } else if (team1.contains("SASSARI")) {
          team1Input = "sassari";
        } else if (team1.contains("NOVGOROD")) {
          team1Input = "novgorod";
        } else if (team1.contains("TUROW")) {
          team1Input = "turow";
        } else if (team1.contains("NEPTUNAS")) {
          team1Input = "neptunas";
        } else if (team1.contains("NANTERRE")) {
          team1Input = "nanterre";
        } else if (team1.contains("BUDIVELNIK")) {
          team1Input = "budivelnik";
        } else if (team1.contains("MONTEPASCHI")) {
          team1Input = "montepaschi";
        } else if (team1.contains("RYTAS")) {
          team1Input = "vilnius";
        } else if (team1.contains("CANTU")) {
          team1Input = "mapooro";
        } else if (team1.contains("OLIMPIJA")) {
          team1Input = "ljubljana";
        } else if (team1.contains("CHALON")) {
          team1Input = "chalon";
        } else if (team1.contains("ASSECO") || team1.contains("TREFL")) {
          team1Input = "gdynia";
        } else if (team1.contains("BESIKTAS")) {
          team1Input = "besiktas";
        } else if (team1.contains("SLUC")) {
          team1Input = "sluc";
        } else if (team1.contains("BILBAO") || team1.contains("GESCRAP")) {
          team1Input = "bilbao";
        } else if (team1.contains("SPIROU")) {
          team1Input = "spirou";
        } else if (team1.contains("VIRTUS") || team1.contains("LOTTOMATICA")) {
          team1Input = "virtus";
        } else if (team1.contains("CHOLET")) {
          team1Input = "cholet";
        } else if (team1.contains("CIBONA")) {
          team1Input = "cibona";
        } else if (team1.contains("ENTENTE")) {
          team1Input = "entente";
        } else if (team1.contains("OLDENBURG")) {
          team1Input = "oldenburg";
        } else if (team1.contains("MAROUSSI")) {
          team1Input = "maroussi";
        } else if (team1.contains("AIR")) {
          team1Input = "air";
        } else if (team1.contains("SARTHE")) {
          team1Input = "sarthe";
        } else if (team1.contains("JOVENTUT")) {
          team1Input = "joventut";
        } else if (team1.contains("PANIONIOS")) {
          team1Input = "panionios";
        } else if (team1.contains("ARIS")) {
          team1Input = "aris";
        } else if (team1.contains("ROANNE")) {
          team1Input = "roanne";
        }

        if (team2.contains("EFES")) {
          team2Input = "efes";
        } else if (team2.contains("BASKONIA") || team2.contains("CERAMICA")) {
          team2Input = "baskonia";
        } else if (team2.contains("PANATHINAIKOS")) {
          team2Input = "panat";
        } else if (team2.contains("ASVEL")) {
          team2Input = "asvel";
        } else if (team2.contains("BOLOGNA")) {
          team2Input = "bologna";
        } else if (team2.contains("OLYMPIACOS")) {
          team2Input = "olympiacos";
        } else if (team2.contains("ZALGIRIS")) {
          team2Input = "zalgiris";
        } else if (team2.contains("PARTIZAN")) {
          team2Input = "partizan";
        } else if (team2.contains("MONACO")) {
          team2Input = "monaco";
        } else if (team2.contains("MADRID")) {
          team2Input = "real";
        } else if (team2.contains("FENERBAHCE") || team2.contains("FB DOGUS")) {
          team2Input = "fener";
        } else if (team2.contains("ALBA")) {
          team2Input = "alba";
        } else if (team2.contains("VALENCIA")) {
          team2Input = "valencia";
        } else if (team2.contains("MACCABI")) {
          team2Input = "maccabi";
        } else if (team2.contains("MILAN")) {
          team2Input = "milano";
        } else if (team2.contains("CRVENA")) {
          team2Input = "crvena";
        } else if (team2.contains("BARCELONA")) {
          team2Input = "barcelona";
        } else if (team2.contains("BAYERN")) {
          team2Input = "munich";
        } else if (team2.contains("ZENIT")) {
          team2Input = "zenit";
        } else if (team2.contains("UNICS")) {
          team2Input = "unics";
        } else if (team2.contains("CSKA")) {
          team2Input = "cska";
        } else if (team2.contains("KHIMKI")) {
          team2Input = "khimki";
        } else if (team2.contains("BUDUCNOST")) {
          team2Input = "buducnost";
        } else if (team2.contains("CANARIA")) {
          team2Input = "canaria";
        } else if (team2.contains("DARUSSAFAKA")) {
          team2Input = "darussafaka";
        } else if (team2.contains("UNICAJA") || team2.contains("BALONCESTO")) {
          team2Input = "unicaja";
        } else if (team2.contains("GALATASARAY")) {
          team2Input = "galatasaray";
        } else if (team2.contains("BROSE") || team2.contains("BAMBERG")) {
          team2Input = "brose";
        } else if (team2.contains("STRASBOURG")) {
          team2Input = "strasbourg";
        } else if (team2.contains("LABORAL")) {
          team2Input = "baskonia";
        } else if (team2.contains("ZAGREB")) {
          team2Input = "cedevita";
        } else if (team2.contains("LIMOGES")) {
          team2Input = "limoges";
        } else if (team2.contains("ZIELONA")) {
          team2Input = "zielona";
        } else if (team2.contains("KUBAN")) {
          team2Input = "kuban";
        } else if (team2.contains("KARSIYAKA")) {
          team2Input = "karsiyaka";
        } else if (team2.contains("SASSARI")) {
          team2Input = "sassari";
        } else if (team2.contains("NOVGOROD")) {
          team2Input = "novgorod";
        } else if (team2.contains("TUROW")) {
          team2Input = "turow";
        } else if (team2.contains("NEPTUNAS")) {
          team2Input = "neptunas";
        } else if (team2.contains("NANTERRE")) {
          team2Input = "nanterre";
        } else if (team2.contains("BUDIVELNIK")) {
          team2Input = "budivelnik";
        } else if (team2.contains("MONTEPASCHI")) {
          team2Input = "montepaschi";
        } else if (team2.contains("RYTAS")) {
          team2Input = "vilnius";
        } else if (team2.contains("CANTU")) {
          team2Input = "mapooro";
        } else if (team2.contains("OLIMPIJA")) {
          team2Input = "ljubljana";
        } else if (team2.contains("CHALON")) {
          team2Input = "chalon";
        } else if (team2.contains("ASSECO") || team2.contains("TREFL")) {
          team2Input = "gdynia";
        } else if (team2.contains("BESIKTAS")) {
          team2Input = "besiktas";
        } else if (team2.contains("SLUC")) {
          team2Input = "sluc";
        } else if (team2.contains("BILBAO") || team2.contains("GESCRAP")) {
          team2Input = "bilbao";
        } else if (team2.contains("SPIROU")) {
          team2Input = "spirou";
        } else if (team2.contains("VIRTUS") || team2.contains("LOTTOMATICA")) {
          team2Input = "virtus";
        } else if (team2.contains("CHOLET")) {
          team2Input = "cholet";
        } else if (team2.contains("CIBONA")) {
          team2Input = "cibona";
        } else if (team2.contains("ENTENTE")) {
          team2Input = "entente";
        } else if (team2.contains("OLDENBURG")) {
          team2Input = "oldenburg";
        } else if (team2.contains("MAROUSSI")) {
          team2Input = "maroussi";
        } else if (team2.contains("AIR")) {
          team2Input = "air";
        } else if (team2.contains("SARTHE")) {
          team2Input = "sarthe";
        } else if (team2.contains("JOVENTUT")) {
          team2Input = "joventut";
        } else if (team2.contains("PANIONIOS")) {
          team2Input = "panionios";
        } else if (team2.contains("ARIS")) {
          team2Input = "aris";
        } else if (team2.contains("ROANNE")) {
          team2Input = "roanne";
        }

        containerList.add(matchScore(
            team1Input, team2Input, score1Input, score2Input, jsonData));
        setState(() {});
      }
    }
    isOperationsFinished = true;
  }

  //matchScoreView
  Container matchScore(String teamOne, String teamTwo, int scoreOne,
      int scoreTwo, var jsonData) {
    List<Container> firstTeamPlayersContainers = [];
    List<Container> secondTeamPlayersContainers = [];

    for (int y = 0; y < 2; y++) {
      for (int i = 0; i < jsonData["Stats"][y]["PlayersStats"].length; i++) {
        Container a;

        String twoPercent;
        if (int.parse(jsonData["Stats"][y]["PlayersStats"][i]
                    ["FieldGoalsAttempted2"]
                .toString()) !=
            0) {
          twoPercent = (int.parse(jsonData["Stats"][y]["PlayersStats"][i]
                          ["FieldGoalsMade2"]
                      .toString()) /
                  int.parse(jsonData["Stats"][y]["PlayersStats"][i]
                          ["FieldGoalsAttempted2"]
                      .toString()) *
                  100)
              .toStringAsFixed(1);
        } else {
          twoPercent = "0";
        }
        String threePercent;
        if (int.parse(jsonData["Stats"][y]["PlayersStats"][i]
                    ["FieldGoalsAttempted3"]
                .toString()) !=
            0) {
          threePercent = (int.parse(jsonData["Stats"][y]["PlayersStats"][i]
                          ["FieldGoalsMade3"]
                      .toString()) /
                  int.parse(jsonData["Stats"][y]["PlayersStats"][i]
                          ["FieldGoalsAttempted3"]
                      .toString()) *
                  100)
              .toStringAsFixed(1);
        } else {
          threePercent = "0";
        }
        String onePercent;
        if (int.parse(jsonData["Stats"][y]["PlayersStats"][i]
                    ["FreeThrowsAttempted"]
                .toString()) !=
            0) {
          onePercent = (int.parse(jsonData["Stats"][y]["PlayersStats"][i]
                          ["FreeThrowsMade"]
                      .toString()) /
                  int.parse(jsonData["Stats"][y]["PlayersStats"][i]
                          ["FreeThrowsAttempted"]
                      .toString()) *
                  100)
              .toStringAsFixed(1);
        } else {
          onePercent = "0";
        }
        if (jsonData["Stats"][y]["PlayersStats"][i]["Player"].toString() ==
            jsonData["Stats"][y]["PlayersStats"][i]["Player"]
                .toString()
                .toUpperCase()) {
          List<String> newName = jsonData["Stats"][y]["PlayersStats"][i]
                  ["Player"]
              .toString()
              .split(", ");
          String name1 = newName[1].substring(0, 1).toUpperCase() +
              newName[1].substring(1).toLowerCase();
          String name0 = newName[0].substring(0, 1).toUpperCase() +
              newName[0].substring(1).toLowerCase();
          jsonData["Stats"][y]["PlayersStats"][i]["Player"] = "$name1 $name0";
        }
        a = Container(
          decoration: BoxDecoration(
            border: Border.all(width: 0, color: Colors.transparent),
            color: Colors.white,
          ),
          padding: const EdgeInsets.only(bottom: 10.0),
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]["Player"]
                                  .toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 1,
                        color: Colors.black,
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Points: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]["Points"]
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Rebounds: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]
                                      ["TotalRebounds"]
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Assistances: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]
                                      ["Assistances"]
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Minutes: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]["Minutes"]
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "2 pointers: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${jsonData["Stats"][y]["PlayersStats"][i]["FieldGoalsMade2"].toString()}/${jsonData["Stats"][y]["PlayersStats"][i]["FieldGoalsAttempted2"].toString()} - $twoPercent%",
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "3 pointers: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${jsonData["Stats"][y]["PlayersStats"][i]["FieldGoalsMade3"].toString()}/${jsonData["Stats"][y]["PlayersStats"][i]["FieldGoalsAttempted3"].toString()} - $threePercent%",
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Free Throws: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${jsonData["Stats"][y]["PlayersStats"][i]["FreeThrowsMade"].toString()}/${jsonData["Stats"][y]["PlayersStats"][i]["FreeThrowsAttempted"].toString()} - $onePercent%",
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Offensive Rebounds: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]
                                      ["OffensiveRebounds"]
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Defensive Rebounds: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]
                                      ["DefensiveRebounds"]
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Turnovers: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]
                                      ["Turnovers"]
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Steals: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]["Steals"]
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Blocks: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]
                                      ["BlocksFavour"]
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Fouls: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]
                                      ["FoulsCommited"]
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Efficiency: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              jsonData["Stats"][y]["PlayersStats"][i]
                                      ["Valuation"]
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width) / 2,
                  child: Text(
                      jsonData["Stats"][y]["PlayersStats"][i]["Player"]
                          .toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text(
                      jsonData["Stats"][y]["PlayersStats"][i]["Minutes"]
                          .toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text(
                      jsonData["Stats"][y]["PlayersStats"][i]["TotalRebounds"]
                          .toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text(
                      jsonData["Stats"][y]["PlayersStats"][i]["Assistances"]
                          .toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text(
                      jsonData["Stats"][y]["PlayersStats"][i]["Points"]
                          .toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );

        if (y == 0) {
          firstTeamPlayersContainers.add(a);
        } else {
          secondTeamPlayersContainers.add(a);
        }
      }
    }

    Icon triangle;

    if (scoreOne > scoreTwo) {
      triangle = const Icon(Icons.arrow_left, color: Colors.grey);
    } else if (scoreOne < scoreTwo) {
      triangle = const Icon(Icons.arrow_right, color: Colors.grey);
    } else {
      triangle = const Icon(Icons.arrow_drop_up, color: Colors.transparent);
    }

    final imageHeight = MediaQuery.of(context).size.height / 7 * (3 / 4);
    final score = Text("$scoreOne - $scoreTwo",
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: MediaQuery.of(context).size.height / 7,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 3),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: imageHeight,
            child: InkWell(
              onTap: () {
                // Show the Player information when the container is clicked
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 35 + firstTeamPlayersContainers.length * 27,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width:
                                      (MediaQuery.of(context).size.width) / 2,
                                  child: const Text("Player",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                const Expanded(
                                  child: Text("Min",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                const Expanded(
                                  child: Text("Reb",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                const Expanded(
                                  child: Text("Ast",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                const Expanded(
                                  child: Text("Pts",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 1,
                            color: Colors.black,
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent),
                              color: Colors.transparent,
                            ),
                            constraints: BoxConstraints.expand(
                                height: firstTeamPlayersContainers.length * 27),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Flexible(
                                  child: ListView.builder(
                                    itemCount:
                                        firstTeamPlayersContainers.length,
                                    itemBuilder: (context, index) =>
                                        firstTeamPlayersContainers[index],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    child: Image.asset('assets/$teamOne.png',
                        height: imageHeight, fit: BoxFit.contain),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              // Show the General statistics of teams
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                jsonData["Stats"][0]["Team"],
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("Team Stats",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                jsonData["Stats"][1]["Team"],
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${int.parse(jsonData["Stats"][0]["totr"]["FieldGoalsMade2"].toString()) + int.parse(jsonData["Stats"][0]["totr"]["FieldGoalsMade3"].toString())}/${int.parse(jsonData["Stats"][0]["totr"]["FieldGoalsAttempted2"].toString()) + int.parse(jsonData["Stats"][0]["totr"]["FieldGoalsAttempted3"].toString())}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("Field Goals",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                "${int.parse(jsonData["Stats"][1]["totr"]["FieldGoalsMade2"].toString()) + int.parse(jsonData["Stats"][1]["totr"]["FieldGoalsMade3"].toString())}/${int.parse(jsonData["Stats"][1]["totr"]["FieldGoalsAttempted2"].toString()) + int.parse(jsonData["Stats"][1]["totr"]["FieldGoalsAttempted3"].toString())}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${int.parse(jsonData["Stats"][0]["totr"]["FieldGoalsMade3"].toString())}/${int.parse(jsonData["Stats"][0]["totr"]["FieldGoalsAttempted3"].toString())}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("3 pointers",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                "${int.parse(jsonData["Stats"][1]["totr"]["FieldGoalsMade3"].toString())}/${int.parse(jsonData["Stats"][1]["totr"]["FieldGoalsAttempted3"].toString())}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][0]["totr"]["FreeThrowsMade"]}/${jsonData["Stats"][0]["totr"]["FreeThrowsAttempted"].toString()}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("Free throws",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][1]["totr"]["FreeThrowsMade"]}/${jsonData["Stats"][1]["totr"]["FreeThrowsAttempted"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][0]["totr"]["TotalRebounds"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("Total rebounds",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][1]["totr"]["TotalRebounds"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][0]["totr"]["OffensiveRebounds"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("(Offensive rebounds)",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][1]["totr"]["OffensiveRebounds"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][0]["totr"]["DefensiveRebounds"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("(Defensive rebounds)",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][1]["totr"]["DefensiveRebounds"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][0]["totr"]["Assistances"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("Assists",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][1]["totr"]["Assistances"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][0]["totr"]["BlocksFavour"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("Blocks",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][1]["totr"]["BlocksFavour"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][0]["totr"]["Steals"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("Steals",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][1]["totr"]["Steals"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][0]["totr"]["Turnovers"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("Turnovers",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][1]["totr"]["Turnovers"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][0]["totr"]["FoulsCommited"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Expanded(
                              child: Text("Fouls Commited",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                "${jsonData["Stats"][1]["totr"]["FoulsCommited"]}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              score,
              triangle,
            ]),
          ),
          SizedBox(
            width: imageHeight,
            child: InkWell(
              onTap: () {
                // Show the Player information when the container is clicked
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 35 + secondTeamPlayersContainers.length * 27,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width:
                                      (MediaQuery.of(context).size.width) / 2,
                                  child: const Text("Player",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                const Expanded(
                                  child: Text("Min",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                const Expanded(
                                  child: Text("Reb",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                const Expanded(
                                  child: Text("Ast",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                const Expanded(
                                  child: Text("Pts",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 1,
                            color: Colors.black,
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent),
                              color: Colors.transparent,
                            ),
                            constraints: BoxConstraints.expand(
                                height:
                                    secondTeamPlayersContainers.length * 27),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Flexible(
                                  child: ListView.builder(
                                    itemCount:
                                        secondTeamPlayersContainers.length,
                                    itemBuilder: (context, index) =>
                                        secondTeamPlayersContainers[index],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: Image.asset(
                      'assets/$teamTwo.png',
                      height: imageHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void deleteMatches() {
    containerList.clear();
  }

  //team options
  List<String> teams = [
    "Hepsi",
    "Anadolu Efes Istanbul",
    "Olympiacos Piraeus",
    "Real Madrid",
    "Fenerbahce Beko Istanbul",
    "FC Barcelona",
    "Zalgiris Kaunas",
    "AS Monaco",
    "Cazoo Baskonia Vitoria-Gasteiz",
    "Maccabi Playtika Tel Aviv",
    "Crvena Zvezda Mts Belgrade",
    "Valencia Basket",
    "Partizan Mozzart Bet Belgrade",
    "Virtus Segafredo Bologna",
    "FC Bayern Munich",
    "LDLC Asvel Villeurbanne",
    "Panathinaikos Athens",
    "Alba Berlin",
    "EA7 Emporio Armani Milan"
  ];

  //default selectedTeam value
  String selectedTeam = "Hepsi";

  //season options
  List<String> seasons = [
    "2022",
    "2021",
    "2020",
    "2019",
    "2018",
    "2017",
    "2016",
    "2015",
    "2014",
    "2013",
    "2012",
    "2011",
    "2010",
    "2009",
    "2008",
    "2007"
  ];
  bool isFilterVisible = true;

  bool isScheduleSelected = false;
  bool isResultsSelected = true;
  bool isStandingsSelected = false;

  //default selectedSeason value
  String selectedSeason = "2022";


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: !isOperationsFinished
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if ((scrollNotification is ScrollUpdateNotification) &&
                      isOperationsFinished && isResultsSelected) {
                    printSelected();
                  }
                  return false;
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent),
                      color: Colors.transparent),
                  height: MediaQuery.of(context).size.height -
                      (kToolbarHeight + MediaQuery.of(context).padding.top),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: ListView.builder(
                          itemCount: containerList.length,
                          itemBuilder: (context, index) => containerList[index],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFA5601),
        leading: PopupMenuButton<String>(
          icon: Icon(Icons.menu, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case "Standings":
                isScheduleSelected = false;
                isResultsSelected = false;
                isStandingsSelected = true;
                deleteMatches();
                isFilterVisible = false;
                setState(() {});
                break;
              case "Results":
                isScheduleSelected = false;
                isResultsSelected = true;
                isStandingsSelected = false;
                deleteMatches();
                isFilterVisible = true;
                printSelected();
                setState(() {});
                break;
              case "Schedule":
                isScheduleSelected = true;
                isResultsSelected = false;
                isStandingsSelected = false;
                deleteMatches();
                isFilterVisible = false;
                printSchedule();
                setState(() {});
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: "Standings",
              child: Text("Standings"),
            ),
            const PopupMenuItem<String>(
              value: "Results",
              child: Text("Results"),
            ),
            const PopupMenuItem<String>(
              value: "Schedule",
              child: Text("Schedule"),
            ),
          ],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/euroleagueLogo.png",
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 8),
            const Text(
              "EuroLeague Statistics",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: <Widget>[
          Visibility(
            visible: isFilterVisible,
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Column(
                          children: <Widget>[
                            ListTile(
                              leading: const Icon(Icons.date_range),
                              trailing: DropdownButton<String>(
                                value: selectedSeason,
                                items: seasons.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedSeason = newValue ?? "";
                                    selectedTeam = "Hepsi";
                                    if (newValue == "2022") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes Istanbul");
                                      teams.add("Fenerbahce Beko Istanbul");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add("Real Madrid");
                                      teams.add("FC Barcelona");
                                      teams.add("Zalgiris Kaunas");
                                      teams.add("AS Monaco");
                                      teams.add(
                                          "Cazoo Baskonia Vitoria-Gasteiz");
                                      teams.add("Maccabi Playtika Tel Aviv");
                                      teams.add("Crvena Zvezda Mts Belgrade");
                                      teams.add("Valencia Basket");
                                      teams
                                          .add("Partizan Mozzart Bet Belgrade");
                                      teams.add("Virtus Segafredo Bologna");
                                      teams.add("FC Bayern Munich");
                                      teams.add("LDLC Asvel Villeurbanne");
                                      teams.add("Panathinaikos Athens");
                                      teams.add("Alba Berlin");
                                      teams.add("EA7 Emporio Armani Milan");
                                    } else if (newValue == "2021") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes Istanbul");
                                      teams.add("Fenerbahce Beko Istanbul");
                                      teams.add("Alba Berlin");
                                      teams.add("AX Armani Exchange Milan");
                                      teams.add("FC Barcelona");
                                      teams.add("Baskonia Vitoria-Gasteiz");
                                      teams.add("FC Bayern Munich");
                                      teams.add("Crvena Zvezda Mts Belgrade");
                                      teams.add("CSKA Moscow");
                                      teams.add("LDLC Asvel Villeurbanne");
                                      teams.add("Maccabi Playtika Tel Aviv");
                                      teams.add("AS Monaco");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add("Panathinaikos OPAP Athens");
                                      teams.add("Real Madrid");
                                      teams.add("UNICS Kazan");
                                      teams.add("Zalgiris Kaunas");
                                      teams.add("Zenit Saint Petersburg");
                                    } else if (newValue == "2020") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes Istanbul");
                                      teams.add("Fenerbahce Beko Istanbul");
                                      teams.add("Alba Berlin");
                                      teams.add("AX Armani Exchange Milan");
                                      teams.add("FC Barcelona");
                                      teams.add(
                                          "TD Systems Baskonia Vitoria-Gasteiz");
                                      teams.add("FC Bayern Munich");
                                      teams.add("Crvena Zvezda Mts Belgrade");
                                      teams.add("CSKA Moscow");
                                      teams.add("LDLC Asvel Villeurbanne");
                                      teams.add("Maccabi Playtika Tel Aviv");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add("Panathinaikos OPAP Athens");
                                      teams.add("Real Madrid");
                                      teams.add("Khimki Moscow Region");
                                      teams.add("Zalgiris Kaunas");
                                      teams.add("Zenit Saint Petersburg");
                                      teams.add("Valencia Basket");
                                    } else if (newValue == "2019") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes Istanbul");
                                      teams.add("Fenerbahce Beko Istanbul");
                                      teams.add("Alba Berlin");
                                      teams.add("AX Armani Exchange Milan");
                                      teams.add("FC Barcelona");
                                      teams.add(
                                          "Kirolbet Baskonia Vitoria-Gasteiz");
                                      teams.add("FC Bayern Munich");
                                      teams.add("Crvena Zvezda Mts Belgrade");
                                      teams.add("CSKA Moscow");
                                      teams.add("LDLC Asvel Villeurbanne");
                                      teams.add("Maccabi Fox Tel Aviv");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add("Panathinaikos OPAP Athens");
                                      teams.add("Real Madrid");
                                      teams.add("Khimki Moscow Region");
                                      teams.add("Zalgiris Kaunas");
                                      teams.add("Zenit St Petersburg");
                                      teams.add("Valencia Basket");
                                    } else if (newValue == "2018") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes Istanbul");
                                      teams.add("Fenerbahce Istanbul");
                                      teams.add(
                                          "AX Armani Exchange Olimpia Milan");
                                      teams.add("FC Barcelona Lassa");
                                      teams.add("FC Bayern Munich");
                                      teams.add("Buducnost Voli Podgorica");
                                      teams.add("CSKA Moscow");
                                      teams.add("Darussafaka Tekfen Istanbul");
                                      teams.add("Herbalife Gran Canaria");
                                      teams.add("Khimki Moscow Region");
                                      teams.add(
                                          "Kirolbet Baskonia Vitoria-Gasteiz");
                                      teams.add("Maccabi Fox Tel Aviv");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add("Panathinaikos OPAP Athens");
                                      teams.add("Real Madrid");
                                      teams.add("Zalgiris Kaunas");
                                    } else if (newValue == "2017") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes Istanbul");
                                      teams.add("Fenerbahce Dogus Istanbul");
                                      teams.add(
                                          "AX Armani Exchange Olimpia Milan");
                                      teams.add("Brose Bamberg");
                                      teams.add("Crvena Zvezda Mts Belgrade");
                                      teams.add("CSKA Moscow");
                                      teams.add("FC Barcelona Lassa");
                                      teams.add("Khimki Moscow Region");
                                      teams.add("Baskonia Vitoria Gasteiz");
                                      teams.add("Maccabi Fox Tel Aviv");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add(
                                          "Panathinaikos Superfoods Athens");
                                      teams.add("Real Madrid");
                                      teams.add("Unicaja Malaga");
                                      teams.add("Valencia Basket");
                                      teams.add("Zalgiris Kaunas");
                                    } else if (newValue == "2016") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes Istanbul");
                                      teams.add("Fenerbahce Istanbul");
                                      teams.add("Baskonia Vitoria Gasteiz");
                                      teams.add("Brose Bamberg");
                                      teams.add("Crvena Zvezda Mts Belgrade");
                                      teams.add("CSKA Moscow");
                                      teams.add("Darussafaka Dogus Istanbul");
                                      teams.add("EA7 Emporio Armani Milan");
                                      teams.add("FC Barcelona Lassa");
                                      teams
                                          .add("Galatasaray Odeabank Istanbul");
                                      teams.add("Maccabi Fox Tel Aviv");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add(
                                          "Panathinaikos Superfoods Athens");
                                      teams.add("Real Madrid");
                                      teams.add("UNICS Kazan");
                                      teams.add("Zalgiris Kaunas");
                                    } else if (newValue == "2015") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes Istanbul");
                                      teams.add("Fenerbahce Istanbul");
                                      teams.add("Khimki Moscow Region");
                                      teams.add("Real Madrid");
                                      teams.add(
                                          "Crvena Zvezda Telekom Belgrade");
                                      teams.add("Strasbourg");
                                      teams.add("FC Bayern Munich");
                                      teams.add("EA7 Emporio Armani Milan");
                                      teams
                                          .add("Laboral Kutxa Vitoria Gasteiz");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add("Cedevita Zagreb");
                                      teams.add("Limoges CSP");
                                      teams.add("Zalgiris Kaunas");
                                      teams.add("Stelmet Zielona Gora");
                                      teams.add("Panathinaikos Athens");
                                      teams.add("Lokomotiv Kuban Krasnodar");
                                      teams.add("Pinar Karsiyaka Izmir");
                                      teams.add("FC Barcelona Lassa");
                                      teams.add("Unicaja Malaga");
                                      teams.add("Brose Baskets Bamberg");
                                      teams.add("Darussafaka Dogus Istanbul");
                                      teams.add(
                                          "Dinamo Banco Di Sardegna Sassari");
                                      teams.add("CSKA Moscow");
                                      teams.add("Maccabi Fox Tel Aviv");
                                    } else if (newValue == "2014") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes Istanbul");
                                      teams.add("Fenerbahce Ulker Istanbul");
                                      teams.add("Real Madrid");
                                      teams.add("Zalgiris Kaunas");
                                      teams.add(
                                          "Dinamo Banco Di Sardegna Sassari");
                                      teams.add("Nizhny Novgorod");
                                      teams.add("UNICS Kazan");
                                      teams.add("Alba Berlin");
                                      teams.add("CSKA Moscow");
                                      teams.add("Maccabi Electra Tel Aviv");
                                      teams.add("Limoges CSP");
                                      teams.add("Cedevita Zagreb");
                                      teams.add("Unicaja Malaga");
                                      teams.add("Panathinaikos Athens");
                                      teams.add("PGE Turow Zgorzelec");
                                      teams.add("EA7 Emporio Armani Milan");
                                      teams.add("FC Barcelona");
                                      teams.add("FC Bayern Munich");
                                      teams.add(
                                          "Crvena Zvezda Telekom Belgrade");
                                      teams.add(
                                          "Galatasaray Liv Hospital Istanbul");
                                      teams.add("Valencia Basket");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add("Laboral Kutxa Vitoria");
                                      teams.add("Neptunas Klaipeda");
                                    } else if (newValue == "2013") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes Istanbul");
                                      teams.add("Fenerbahce Ulker Istanbul");
                                      teams.add("FC Barcelona");
                                      teams.add("Partizan Nis Belgrade");
                                      teams.add("JSF Nanterre");
                                      teams.add("CSKA Moscow");
                                      teams.add("Budivelnik Kiev");
                                      teams.add("Brose Baskets Bamberg");
                                      teams.add("Strasbourg");
                                      teams.add("EA7 Emporio Armani Milan");
                                      teams.add("Zalgiris Kaunas");
                                      teams.add("Real Madrid");
                                      teams.add("Stelmet Zielona Gora");
                                      teams.add("FC Bayern Munich");
                                      teams.add("Montepaschi Siena");
                                      teams.add(
                                          "Galatasaray Liv Hospital Istanbul");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add("Unicaja Malaga");
                                      teams.add("Lietuvos Rytas Vilnius");
                                      teams.add("Panathinaikos Athens");
                                      teams.add("Laboral Kutxa Vitoria");
                                      teams.add("Maccabi Electra Tel Aviv");
                                      teams.add(
                                          "Crvena Zvezda Telekom Belgrade");
                                      teams.add("Lokomotiv Kuban Krasnodar");
                                    } else if (newValue == "2012") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes Istanbul");
                                      teams.add("Fenerbahce Ulker Istanbul");
                                      teams.add("BC Khimki Moscow Region");
                                      teams.add("Real Madrid");
                                      teams.add("Panathinaikos Athens");
                                      teams.add("Mapooro Cantu");
                                      teams.add("Union Olimpija Ljubljana");
                                      teams.add("Unicaja Malaga");
                                      teams.add("Maccabi Electra Tel Aviv");
                                      teams.add("Montepaschi Siena");
                                      teams.add("Alba Berlin");
                                      teams.add("Elan Chalon-Sur-Saone");
                                      teams.add("Asseco Prokom Gdynia");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add("Caja Laboral Vitoria");
                                      teams.add("Zalgiris Kaunas");
                                      teams.add("Cedevita Zagreb");
                                      teams.add("EA7 Emporio Armani Milano");
                                      teams.add("FC Barcelona Regal");
                                      teams.add("Brose Baskets Bamberg");
                                      teams.add("Besiktas JK Istanbul");
                                      teams.add("Partizan MT:S Belgrade");
                                      teams.add("CSKA Moscow");
                                      teams.add("Lietuvos Rytas Vilnius");
                                    } else if (newValue == "2011") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Anadolu Efes");
                                      teams.add("Fenerbahce Ulker");
                                      teams.add("Bennet Cantu");
                                      teams.add("Sluc Nancy");
                                      teams.add("Bilbao Basket");
                                      teams.add("Olympiacos");
                                      teams.add("Caja Laboral");
                                      teams.add("Panathinaikos");
                                      teams.add("Unicaja");
                                      teams.add("Zalgiris");
                                      teams.add("CSKA Moscow");
                                      teams.add("Brose Baskets");
                                      teams.add("KK Zagreb");
                                      teams.add("Partizan MT:S");
                                      teams.add("Belgacom Spirou");
                                      teams.add("Real Madrid");
                                      teams.add("EA7 Emporio Armani Milan");
                                      teams.add("Maccabi Electra");
                                      teams.add("Union Olimpija");
                                      teams.add("FC Barcelona Regal");
                                      teams.add("Asseco Prokom");
                                      teams.add("Galatasaray Medical Park");
                                      teams.add("UNICS");
                                      teams.add("Montepaschi Siena");
                                    } else if (newValue == "2010") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Efes Pilsen Istanbul");
                                      teams.add("Fenerbahce Ulker");
                                      teams.add("BC Khimki");
                                      teams.add("Asseco Prokom Gdynia");
                                      teams.add("Caja Laboral Baskonia");
                                      teams.add("Maccabi Electra Tel Aviv");
                                      teams.add("Zalgiris");
                                      teams.add("Partizan");
                                      teams.add("Olympiacos");
                                      teams.add("Real Madrid");
                                      teams.add("Unicaja");
                                      teams.add("Spirou Basket");
                                      teams.add("Virtus Roma");
                                      teams.add("Brose Baskets");
                                      teams.add("Regal FC Barcelona");
                                      teams.add("Cibona");
                                      teams.add("Lietuvos Rytas");
                                      teams.add("Montepaschi Siena");
                                      teams.add("Cholet Basket");
                                      teams.add("Power Electronics Valencia");
                                      teams.add("Panathinaikos");
                                      teams.add("CSKA Moscow");
                                      teams.add("Armani Jeans Milano");
                                      teams.add("Union Olimpija");
                                    } else if (newValue == "2009") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Efes Pilsen Istanbul");
                                      teams.add("Fenerbahce Ulker");
                                      teams.add("Regal FC Barcelona");
                                      teams.add("Cibona");
                                      teams.add("Montepaschi Siena");
                                      teams.add("Zalgiris");
                                      teams.add("Asvel Lyon");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add("Entente Orleanaise");
                                      teams.add("Lietuvos Rytas");
                                      teams.add("Partizan");
                                      teams.add("Unicaja");
                                      teams.add("Maroussi BC");
                                      teams.add("CSKA Moscow");
                                      teams.add("Lottomatica Roma");
                                      teams.add("Caja Laboral Baskonia");
                                      teams.add("Maccabi Electra Tel Aviv");
                                      teams.add("Union Olimpija");
                                      teams.add("Asseco Prokom Gdynia");
                                      teams.add("Ewe Baskets Oldenburg");
                                      teams.add("Armani Jeans Milano");
                                      teams.add("Panathinaikos");
                                      teams.add("BC Khimki");
                                      teams.add("Real Madrid");
                                    } else if (newValue == "2008") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Efes Pilsen Istanbul");
                                      teams.add("Fenerbahce Ulker");
                                      teams.add("Air Avellino");
                                      teams.add("Olympiacos Piraeus");
                                      teams.add("Unicaja");
                                      teams.add("Le Mans Sarthe Basket");
                                      teams.add("Cibona");
                                      teams.add("Maccabi Electra Tel Aviv");
                                      teams.add("Sluc Nancy");
                                      teams.add("FC Barcelona");
                                      teams.add("Panathinaikos");
                                      teams.add("Zalgiris");
                                      teams.add("Montepaschi Siena");
                                      teams.add("Asseco Prokom Sopot");
                                      teams.add("Tau Ceramica");
                                      teams.add("Alba Berlin");
                                      teams.add("Lottomatica Roma");
                                      teams.add("Union Olimpija");
                                      teams.add("DKV Joventut");
                                      teams.add("Real Madrid");
                                      teams.add("Panionios On Telecoms");
                                      teams.add("CSKA Moscow");
                                      teams.add("Armani Jeans Milano");
                                      teams.add("Partizan");
                                    } else if (newValue == "2007") {
                                      teams.clear();
                                      teams.add("Hepsi");
                                      teams.add("Efes Pilsen Istanbul");
                                      teams.add("Fenerbahce Ulker");
                                      teams.add("Olympiacos Piraeus B.C.");
                                      teams.add("Baskonia");
                                      teams.add("Virtus Vidivici Bologna");
                                      teams.add("Zalgiris Kaunas");
                                      teams.add("Prokom Trefl Sopot");
                                      teams.add("CSKA Moscow");
                                      teams.add("Montepaschi");
                                      teams.add("Olimpija");
                                      teams.add("Aris Thessaloniki");
                                      teams.add("Baloncesto Malaga");
                                      teams.add("KK Cibona");
                                      teams.add("Milano");
                                      teams.add("Lietuvos Rytas");
                                      teams.add("Maccabi Tel Aviv");
                                      teams.add("Le Mans Sarthe Basket");
                                      teams.add("Real Madrid");
                                      teams.add("Panathinaikos");
                                      teams.add("Virtus Roma");
                                      teams.add("Baskets Bamberg");
                                      teams.add("Roanne");
                                      teams.add("Partizan BC");
                                      teams.add("FC Barcelona");
                                      teams.add("Union Olimpija");
                                      teams.add("Olympiacos Piraeus");
                                    }
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.group),
                              trailing: DropdownButton<String>(
                                value: selectedTeam,
                                items: teams.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedTeam = newValue ?? "";
                                  });
                                },
                              ),
                            ),
                            Container(
                              alignment: Alignment.bottomRight,
                              padding: const EdgeInsets.only(
                                  right: 10.0, bottom: 10.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (isOperationsFinished) {
                                    containerList.clear();
                                    setState(() {});
                                    printSelected();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFA5601),
                                ),
                                child: const Icon(Icons.search),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
