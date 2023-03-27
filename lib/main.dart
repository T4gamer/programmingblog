import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() async {
  // We're using HiveStore for persistence,
  // so we need to initialize Hive.
  await initHiveForFlutter();

  final HttpLink httpLink = HttpLink(
    'https://api.hashnode.com/',
  );

  final AuthLink authLink = AuthLink(
    getToken: () async => 'Bearer <>',
    // OR
    // getToken: () => 'Bearer <YOUR_PERSONAL_ACCESS_TOKEN>',
  );

  final Link link = authLink.concat(httpLink);

  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: link,
      // The default store is the InMemoryStore, which does NOT persist to disk
      cache: GraphQLCache(store: HiveStore()),
    ),
  );

  runApp(
    GraphQLProvider(
      client: client,
      child: MaterialApp(
        title: 'Kotlin Blog',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyApp(),
      ),
    ),
  );
}

Widget getImage(String img) {
  if (img != "") {
    return Image.network(
      img,
      height: 224,
    );
  } else {
    img =
        "https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg";
    return Image.network(
      img,
      height: 224,
    );
  }
}

Column post(String title, String image, String username) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        getImage(image),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 10),
        Text(
          username,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MyHomePage(title: "home");
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  var readBlogs = "";
  var isUserData = false;
  var name = "";
  var coverimage = "";
  var title = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    readBlogs = """
               query{
            storiesFeed(type: BEST) {
              title
              coverImage
              author {
                name
              }
            }
          }
    """;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Query(
        options: QueryOptions(
          document: gql(readBlogs),
        ),
        builder: (QueryResult result,
            {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.hasException) {
            refetch!();
          }
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          List posts = [
            {"title": "NONE"}
          ];
          var postslen = 0;
          if (result.data!['storiesFeed'] != null && !isUserData) {
            posts = result.data!['storiesFeed'];
            postslen = posts.length;
          }else {
            posts = result.data!["user"]["publication"]["posts"];
            postslen = posts.length;
          }
          return Column(
            children: <Widget>[
              const SizedBox(
                height: 48,
              ),
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(size: 40, Icons.menu),
                      onPressed: () {},
                    ),
                    const SizedBox(
                      width: 32,
                    ),
                    SizedBox(
                      width: 256,
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              readBlogs = """query{
                                user(username:"${_searchController.text}"){
                                name
                                publication{
                                  posts{
                                    title
                                    coverImage
                                    }
                                  }
                                }
                              }
                              """;
                              isUserData = true;
                              refetch!();
                              setState(() {

                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          labelText: 'Search',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 32,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20.0),
                child: SizedBox(
                    width: double.infinity,
                    child: Text("Kotlin Blog",
                        style: TextStyle(fontSize: 36),
                        textAlign: TextAlign.start)),
              ),
              TabBar(
                controller: _tabController,
                indicator: const UnderlineTabIndicator(
                    insets: EdgeInsets.fromLTRB(50.0, 0.0, 50.0, 40.0),
                    borderSide: BorderSide(color: Colors.black)),
                labelColor: Colors.black,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      readBlogs = """query{
                        storiesFeed(type: BEST) {
                          title
                          coverImage
                          author {
                            name
                          }
                        }
                      }""";
                      isUserData = false;
                      setState(() {

                      });
                      break;
                    case 1:
                      readBlogs = """query{
                        storiesFeed(type: COMMUNITY) {
                          title
                          coverImage
                          author {
                            name
                          }
                        }
                      }""";
                      isUserData = false;
                      setState(() {

                      });
                      break;
                    case 2:
                      readBlogs = """query{
                        storiesFeed(type: FEATURED) {
                          title
                          coverImage
                          author {
                            name
                          }
                        }
                      }""";
                      isUserData = false;
                      setState(() {

                      });
                      break;
                  }
                  setState(() {});
                },
                tabs: const [
                  Tab(
                    text: "Best",
                  ),
                  Tab(
                    text: "COMMUNITY",
                  ),
                  Tab(
                    text: "Featured",
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: postslen,
                  itemBuilder: (context, index) {
                    if(isUserData){
                      return ListTile(
                        title: post(
                          posts[index]["title"],
                          posts[index]["coverImage"],
                          result.data!["user"]["name"]
                        ),
                      );
                    }else{
                      return ListTile(
                        title: post(
                          posts[index]["title"],
                          posts[index]["coverImage"],
                          posts[index]["author"]["name"],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
