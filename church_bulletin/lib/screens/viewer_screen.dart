import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bulletin_model.dart';
import 'admin_screen.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  String? _selectedBulletinId;

  Future<void> _openYoutube(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openFullScreenImage(BuildContext context, String imageUrl, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('사진 ${index + 1} (확대 가능)'),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A5F);

    return Scaffold(
      backgroundColor: const Color(0xFFEAECEF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('주간 주보', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: '관리자 페이지',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('DaebangBulletins')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('등록된 주보가 없습니다.'));
          }

          final bulletins = docs.map((d) => Bulletin.fromFirestore(d)).toList();
          final b = bulletins.firstWhere(
            (item) => item.id == _selectedBulletinId,
            orElse: () => bulletins.first,
          );

          // 화면 가로 크기를 감지하여 모바일(< 520px)과 웹(>= 520px) 레이아웃 분기
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 520;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      // 0. 주보 날짜 선택기
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month,
                                color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: b.id,
                                  isExpanded: true,
                                  items: bulletins.map((item) {
                                    return DropdownMenuItem(
                                      value: item.id,
                                      child: Text(
                                        '${item.date} (${item.volume})',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedBulletinId = val),
                                ),
                              ),
                            ),
                            if (b.youtubeUrl.isNotEmpty)
                              FilledButton.icon(
                                onPressed: () => _openYoutube(b.youtubeUrl),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                ),
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: const Text('예배영상',
                                    style: TextStyle(fontSize: 13)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 1. 주보 표지 헤더 카드
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: primaryColor.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(b.volume,
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 13)),
                                Text(b.date,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                            const Divider(height: 20),
                            Text(
                              '표어: ${b.motto}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '범사에 그에게까지 자랄지라 그는 머리니 곧 그리스도라',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black87),
                            ),
                            Text(
                              '(${b.mottoVerse})',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. 주일 예배 순서표 (모바일: 2줄형 / PC 웹: 3단 점선형 자동 전환)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('주일 예배 (오전 11시)',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text('인도 : ${b.presider}',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '※ 헌금은 예배당 입구에 비치된 헌금함에 미리 넣어주십시오.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                            const Divider(height: 20),

                            _buildResponsiveWorshipRow(
                              isMobile: isMobile,
                              order: '*송영',
                              content: '찬양하라 내 영혼아\n내 속에 있는 것들아 다 찬양하라',
                              person: '다함께',
                            ),
                            _buildResponsiveWorshipRow(
                              isMobile: isMobile,
                              order: '*신앙고백',
                              content: '사도신경',
                              person: '다함께',
                            ),
                            _buildResponsiveWorshipRow(
                              isMobile: isMobile,
                              order: '찬양',
                              content: b.sundayHymn1,
                              person: '다함께',
                            ),
                            _buildResponsiveWorshipRow(
                              isMobile: isMobile,
                              order: '대표기도',
                              content: '',
                              person: b.sundayPrayer,
                              highlightRight: true,
                            ),
                            _buildResponsiveWorshipRow(
                              isMobile: isMobile,
                              order: '교제와광고',
                              content: '',
                              person: '인도자',
                            ),
                            _buildResponsiveWorshipRow(
                              isMobile: isMobile,
                              order: '성경봉독',
                              content: b.sundayScripture,
                              person: '인도자',
                            ),
                            _buildResponsiveSermonRow(
                              isMobile: isMobile,
                              series: b.sermonSeries,
                              title: b.sermonTitle,
                              preacher: b.preacher,
                            ),
                            _buildResponsiveWorshipRow(
                              isMobile: isMobile,
                              order: '헌금과헌신',
                              content: b.offeringHymn,
                              person: '다함께',
                            ),
                            _buildResponsiveWorshipRow(
                              isMobile: isMobile,
                              order: '축도',
                              content: '',
                              person: b.preacher,
                            ),

                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('*표시에서는 일어서 주십시오',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                                Text('다음 주 기도: ${b.nextWeekPrayer}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

// 3. 교회 소식 섹션
                      if (b.announcements.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.campaign, color: primaryColor),
                                  SizedBox(width: 6),
                                  Text('교회 소식',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor)),
                                ],
                              ),
                              const Divider(height: 18),
                              ...b.announcements.map((news) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('▪ ',
                                            style:
                                                TextStyle(color: primaryColor)),
                                        Expanded(
                                          child: Text(news,
                                              style: const TextStyle(
                                                  fontSize: 14, height: 1.4)),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // 4. 선교편지 및 직접 업로드된 활동 사진 갤러리
                      if (b.missionTitle.isNotEmpty ||
                          b.missionContent.isNotEmpty ||
                          b.imageUrls.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (b.missionTitle.isNotEmpty) ...[
                                Text(b.missionTitle,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor)),
                                const Divider(height: 18),
                              ],
                              if (b.imageUrls.isNotEmpty) ...[
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
                                    childAspectRatio: 1.3,
                                  ),
                                  itemCount: b.imageUrls.length,
                                  itemBuilder: (context, idx) {
                                    final url = b.imageUrls[idx];
                                    return GestureDetector(
                                      onTap: () => _openFullScreenImage(
                                          context, url, idx),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(url,
                                            fit: BoxFit.cover),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (b.missionContent.isNotEmpty)
                                Text(
                                  b.missionContent,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.55),
                                ),
                            ],
                          ),
                        ),
                      if (b.missionTitle.isNotEmpty ||
                          b.missionContent.isNotEmpty ||
                          b.imageUrls.isNotEmpty)
                        const SizedBox(height: 12),

                      // 5. 수요예배 및 교회 안내 (Firestore 동적 연동)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            ExpansionTile(
                              title: const Text('수요 예배 (오후 7:30) 순서',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              children: [
                                _buildResponsiveWorshipRow(
                                    isMobile: isMobile,
                                    order: '묵도',
                                    content: '',
                                    person: '다함께'),
                                _buildResponsiveWorshipRow(
                                    isMobile: isMobile,
                                    order: '찬양',
                                    content: b.wedHymn1,
                                    person: '다함께'),
                                _buildResponsiveWorshipRow(
                                    isMobile: isMobile,
                                    order: '기도',
                                    content: '',
                                    person: '다함께'),
                                _buildResponsiveWorshipRow(
                                    isMobile: isMobile,
                                    order: '교제와광고',
                                    content: '',
                                    person: '인도자'),
                                _buildResponsiveWorshipRow(
                                    isMobile: isMobile,
                                    order: '성경봉독',
                                    content: b.wedScripture,
                                    person: '인도자'),
                                _buildResponsiveWorshipRow(
                                    isMobile: isMobile,
                                    order: '말씀선포',
                                    content: b.wedTitle,
                                    person: b.preacher,
                                    highlightCenter: true),
                                _buildResponsiveWorshipRow(
                                    isMobile: isMobile,
                                    order: '찬양',
                                    content: b.wedHymn2,
                                    person: '다함께'),
                                _buildResponsiveWorshipRow(
                                    isMobile: isMobile,
                                    order: '축도',
                                    content: '',
                                    person: b.preacher),
                              ],
                            ),
                            const Divider(height: 1),
                            ExpansionTile(
                              title: const Text('예배 시간 및 섬기는 이들 안내',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              children: [
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('ChurchSettings')
                                      .doc('info')
                                      .snapshots(),
                                  builder: (context, infoSnapshot) {
                                    if (infoSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    final data = infoSnapshot.data?.data()
                                        as Map<String, dynamic>?;
                                    final serviceTimes = data?['serviceTimes'] ??
                                        '예배 시간 정보를 불러오는 중입니다.';
                                    final ministers = data?['ministers'] ??
                                        '섬기는 이들 정보를 등록해 주세요.';

                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '$serviceTimes\n\n[섬기는 이들]\n$ministers',
                                        style: const TextStyle(
                                            fontSize: 13, height: 1.5),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// PC 웹용 자간 균등 배분 위젯
  Widget _buildJustifiedText(String text, TextStyle style) {
    final clean = text.replaceAll(' ', '');
    if (clean.isEmpty) return const SizedBox.shrink();
    if (clean.length == 1) return Text(clean, style: style);

    if (clean.length >= 6) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < clean.length; i++) ...[
              Text(clean[i], style: style),
              if (i < clean.length - 1) const SizedBox(width: 2),
            ],
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: clean.split('').map((char) => Text(char, style: style)).toList(),
    );
  }

  /// 가운데 여백 점선 리더선
  Widget _buildDotLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 4.5).floor();
        if (count <= 1) return const SizedBox.shrink();
        return Text(
          '.' * count,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            letterSpacing: 1.0,
          ),
        );
      },
    );
  }

  /// 모바일(2줄 카드형) / PC 웹(3단 점선형) 자동 전환 예배 순서 행
  Widget _buildResponsiveWorshipRow({
    required bool isMobile,
    required String order,
    required String content,
    required String person,
    bool highlightRight = false,
    bool highlightCenter = false,
  }) {
    const orderStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
    final personStyle = TextStyle(
      fontSize: 13.5,
      fontWeight: highlightRight ? FontWeight.bold : FontWeight.w500,
      color: highlightRight ? const Color(0xFF1E3A5F) : Colors.black87,
    );

    // 1. 모바일 레이아웃: 설명이 있으면 2줄로 분리, 없으면 점선으로 1줄 연결
    if (isMobile) {
      if (content.trim().isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Text(order, style: orderStyle),
              const SizedBox(width: 8),
              Expanded(child: _buildDotLine()),
              const SizedBox(width: 8),
              Text(person, style: personStyle),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(order, style: orderStyle),
                const SizedBox(width: 8),
                Expanded(child: _buildDotLine()),
                const SizedBox(width: 8),
                Text(person, style: personStyle),
              ],
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight:
                      highlightCenter ? FontWeight.bold : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. PC 웹 레이아웃: 전통 종이 주보 3단 가로 배열 + 양옆 점선 리더선
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 88,
            child: _buildJustifiedText(order, orderStyle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: content.trim().isEmpty
                ? _buildDotLine()
                : Row(
                    children: [
                      Expanded(child: _buildDotLine()),
                      Flexible(
                        flex: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            content,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: highlightCenter
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: _buildDotLine()),
                    ],
                  ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: _buildJustifiedText(person, personStyle),
          ),
        ],
      ),
    );
  }

  /// 모바일 / PC 웹 자동 전환 말씀선포 강조 박스
  Widget _buildResponsiveSermonRow({
    required bool isMobile,
    required String series,
    required String title,
    required String preacher,
  }) {
    const orderStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
    const personStyle = TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold);

    // 1. 모바일 레이아웃: 1줄(말씀선포 ... 설교자) / 2줄(강해 시리즈 및 설교 제목)
    if (isMobile) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('말씀선포', style: orderStyle),
                const SizedBox(width: 8),
                Expanded(child: _buildDotLine()),
                const SizedBox(width: 8),
                Text(preacher, style: personStyle),
              ],
            ),
            const SizedBox(height: 8),
            if (series.isNotEmpty)
              Text(
                series,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E3A5F),
                    fontWeight: FontWeight.w600),
              ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15.5, height: 1.35, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // 2. PC 웹 레이아웃: 3단 점선 강조 박스
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: _buildJustifiedText('말씀선포', orderStyle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildDotLine()),
                Flexible(
                  flex: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (series.isNotEmpty)
                          Text(
                            series,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E3A5F),
                                fontWeight: FontWeight.w600),
                          ),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _buildDotLine()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: _buildJustifiedText(preacher, personStyle),
          ),
        ],
      ),
    );
  }
}