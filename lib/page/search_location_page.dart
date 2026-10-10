import 'package:flutter/material.dart';

class SearchLocationPage extends StatefulWidget {
  const SearchLocationPage({super.key});

  @override
  State<SearchLocationPage> createState() => _SearchLocationPageState();
}

class _SearchLocationPageState extends State<SearchLocationPage> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // ให้ TextField Focus หลังจากหน้าโหลดเสร็จ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              label: Icon(Icons.arrow_back_ios, color: Colors.black),
            ),
            Text(
              "ค้นหาสถานที่",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Center(
            child: Container(
              width: 380,
              height: 45,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color.fromARGB(255, 241, 241, 241),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 12),

                          Icon(
                            Icons.search,
                            color: Color.fromARGB(255, 102, 102, 102),
                          ),

                          SizedBox(width: 10),

                          Expanded(
                            child: TextField(
                              controller: searchController,
                              focusNode: searchFocusNode,
                              decoration: const InputDecoration(
                                hintText: "ไปที่ไหน ?",
                                hintStyle: TextStyle(
                                  color: Color.fromARGB(255, 102, 102, 102),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                color: Color.fromARGB(255, 102, 102, 102),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  TextButton(
                    onPressed: () {
                      // คำสั่งค้นหา
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 51, 51),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                    child: const Text(
                      "ค้นหา",
                      style: TextStyle(
                        color: Color.fromARGB(255, 252, 250, 250),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: Colors.red),
                  ),
                  title: const Text(
                    "โรงพยาบาลมหาสารคาม",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      "ต.ตลาด อ.เมืองมหาสารคาม จ.มหาสารคาม",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  onTap: () {
                    print("เลือก โรงพยาบาลมหาสารคาม");
                  },
                ),

                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
