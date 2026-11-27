import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/bulletin_model.dart';
import 'admin_screen.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  String? _selectedBulletinId;
  bool _showYoutubeCard = false;
  YoutubePlayerController? _ytController;
  String? _currentVideoId;

  static const Color primaryColor = Color(0xFF3E4C6D);
  static const Color bgColor = Color(0xFFF4F6F9);

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  void _syncYoutubeController(String url) {
    if (!_showYoutubeCard) {
      if (_ytController != null) {
        _ytController?.close();
        _ytController = null;
        _currentVideoId = null;
      }
      return;
    }

    final videoId = YoutubePlayerController.convertUrlToId(url.trim());
    if (videoId != null && videoId != _currentVideoId) {
      _currentVideoId = videoId;
      _ytController?.close();
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showFullscreenButton: false,
          mute: false,
        ),
      );
    } else if (videoId == null) {
      _currentVideoId = null;
      _ytController?.close();
      _ytController = null;
    }
  }

  void _openFullScreenImage(BuildContext context, String imageUrl, int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 32,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveWorshipRow({
    required bool isMobile,
    required String order,
    required String content,
    required String person,
    bool highlightCenter = false,
  }) {
    final orderStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: isMobile ? 13.5 : 14.5,
      color: primaryColor,
    );
    final contentStyle = TextStyle(
      fontWeight: highlightCenter ? FontWeight.bold : FontWeight.normal,
      fontSize: isMobile ? 14 : 15,
      color: Colors.black87,
    );
    final personStyle = TextStyle(
      fontWeight: highlightCenter ? FontWeight.bold : FontWeight.w500,
      fontSize: isMobile ? 13 : 14,
      color: Colors.black87,
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order, style: orderStyle),
                Text(person, style: personStyle),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 3),
              Container(
                width: double.infinity,
                padding: highlightCenter
                    ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                    : EdgeInsets.zero,
                decoration: highlightCenter
                    ? BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                child: Text(content, style: contentStyle),
              ),
            ],
            const Divider(height: 12, thickness: 0.5),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: highlightCenter
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.symmetric(vertical: 6),
      decoration: highlightCenter
          ? BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(order, style: orderStyle),
          ),
          Expanded(
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: contentStyle,
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              person,
              textAlign: TextAlign.right,
              style: personStyle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          '주간 주보',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('등록된 주보가 없습니다.'));
          }

          final bulletins = snapshot.data!.docs
              .map((doc) => Bulletin.fromFirestore(doc))
              .toList();

          final currentBulletin = bulletins.firstWhere(
            (b) => b.id == _selectedBulletinId,
            orElse: () => bulletins.first,
          );

          final hasYoutube = currentBulletin.youtubeUrl.trim().isNotEmpty;
          _syncYoutubeController(currentBulletin.youtubeUrl);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1-A. 상단 날짜 선택바 & 붉은색 ▶ 예배영상 토글 버튼
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 18, color: primaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: currentBulletin.id,
                                isExpanded: true,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                items: bulletins.map((b) {
                                  return DropdownMenuItem(
                                    value: b.id,
                                    child: Text(
                                      b.volume.isNotEmpty
                                          ? '${b.date.replaceAll('-', '.')} (${b.volume})'
                                          : b.date.replaceAll('-', '.'),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedBulletinId = val;
                                    _showYoutubeCard = false;
                                  });
                                },
                              ),
                            ),
                          ),
                          if (hasYoutube) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _showYoutubeCard = !_showYoutubeCard;
                                });
                              },
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text(
                                '예배영상',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                   // 1-B. 예배영상 버튼 클릭 시 펼쳐지는 인라인 YouTube 플레이어 카드
                    if (hasYoutube && _showYoutubeCard) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFD32F2F),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.ondemand_video,
                                        color: Color(0xFFD32F2F), size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      '주일 예배 실황 영상',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFFD32F2F),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () async {
                                        final uri = Uri.tryParse(
                                            currentBulletin.youtubeUrl.trim());
                                        if (uri != null &&
                                            await canLaunchUrl(uri)) {
                                          await launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      },
                                      icon: const Icon(Icons.fullscreen,
                                          size: 18),
                                      label: const Text(
                                        '크게 보기',
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => setState(
                                          () => _showYoutubeCard = false),
                                      child: const Icon(Icons.close,
                                          size: 18, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_ytController != null)
                              YoutubePlayer(
                                controller: _ytController!,
                                aspectRatio: 16 / 9,
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  '유효하지 않은 YouTube 영상 링크입니다.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // 1-C. 표지 카드 (호수, 날짜, 교회 표어)
                    if (currentBulletin.motto.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currentBulletin.volume,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  currentBulletin.date.replaceAll('-', '.'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Text(
                              '표어: ${currentBulletin.motto}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            if (currentBulletin.mottoVerse.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  currentBulletin.mottoVerse,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 2. 주일 예배 순서 카드
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
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '주일 예배 (오전 11시)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '인도 : ${currentBulletin.presider}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '※ 헌금은 예배당 입구에 비치된 헌금함에 미리 넣어주십시오.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ),
                          const Divider(height: 8),
                          _buildResponsiveWorshipRow(
                            isMobile: isMobile,
                            order: '* 송   영',
                            content: '찬양하라 내 영혼아\n내 속에 있는 것들아 다 찬양하라',
                            person: '다   함   께',
                          ),
                          _buildResponsiveWorshipRow(
                            isMobile: isMobile,
                            order: '* 신 앙 고 백',
                            content: '사도신경',
                            person: '다   함   께',
                          ),
                          _buildResponsiveWorshipRow(
                            isMobile: isMobile,
                            order: '찬      양',
                            content: currentBulletin.sundayHymn1,
                            person: '다   함   께',
                          ),
                          _buildResponsiveWorshipRow(
                            isMobile: isMobile,
                            order: '대 표 기 도',
                            content: '',
                            person: currentBulletin.sundayPrayer,
                          ),
                          _buildResponsiveWorshipRow(
                            isMobile: isMobile,
                            order: '교 제 와 광 고',
                            content: '',
                            person: '인   도   자',
                          ),
                          _buildResponsiveWorshipRow(
                            isMobile: isMobile,
                            order: '성 경 봉 독',
                            content: currentBulletin.sundayScripture,
                            person: '인   도   자',
                          ),
                          _buildResponsiveWorshipRow(
                            isMobile: isMobile,
                            order: '말 씀 선 포',
                            content: currentBulletin.sermonSeries.isNotEmpty
                                ? '[${currentBulletin.sermonSeries}]\n${currentBulletin.sermonTitle}'
                                : currentBulletin.sermonTitle,
                            person: currentBulletin.preacher,
                            highlightCenter: true,
                          ),
                          _buildResponsiveWorshipRow(
                            isMobile: isMobile,
                            order: '헌 금 과 헌 신',
                            content: currentBulletin.offeringHymn,
                            person: '다   함   께',
                          ),
                          _buildResponsiveWorshipRow(
                            isMobile: isMobile,
                            order: '축      도',
                            content: '',
                            person: currentBulletin.presider,
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '*표시에서는 일어서 주십시오',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                              Text(
                                '다음 주 기도: ${currentBulletin.nextWeekPrayer}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. 교회 소식 섹션
                    if (currentBulletin.announcements.isNotEmpty) ...[
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
                                Text(
                                  '교회 소식',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            ...currentBulletin.announcements.map(
                              (news) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('▪ ',
                                        style: TextStyle(color: primaryColor)),
                                    Expanded(
                                      child: Text(
                                        news,
                                        style: const TextStyle(
                                            fontSize: 14, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 4. 선교편지 및 직접 업로드된 활동 사진 갤러리
                    if (currentBulletin.missionTitle.isNotEmpty ||
                        currentBulletin.missionContent.isNotEmpty ||
                        currentBulletin.imageUrls.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentBulletin.missionTitle.isNotEmpty) ...[
                              Text(
                                currentBulletin.missionTitle,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const Divider(height: 18),
                            ],
                            if (currentBulletin.imageUrls.isNotEmpty) ...[
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
                                itemCount: currentBulletin.imageUrls.length,
                                itemBuilder: (context, idx) {
                                  final url = currentBulletin.imageUrls[idx];
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
                            if (currentBulletin.missionContent.isNotEmpty)
                              Text(
                                currentBulletin.missionContent,
                                style: const TextStyle(
                                    fontSize: 14, height: 1.55),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 5. 수요예배 및 교회 안내 (Firestore 동적 연동)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          ExpansionTile(
                            title: const Text(
                              '수요 예배 (오후 7:30) 순서',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            children: [
                              _buildResponsiveWorshipRow(
                                isMobile: isMobile,
                                order: '묵도',
                                content: '',
                                person: '다함께',
                              ),
                              _buildResponsiveWorshipRow(
                                isMobile: isMobile,
                                order: '찬양',
                                content: currentBulletin.wedHymn1,
                                person: '다함께',
                              ),
                              _buildResponsiveWorshipRow(
                                isMobile: isMobile,
                                order: '기도',
                                content: '',
                                person: '다함께',
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
                                content: currentBulletin.wedScripture,
                                person: '인도자',
                              ),
                              _buildResponsiveWorshipRow(
                                isMobile: isMobile,
                                order: '말씀선포',
                                content: currentBulletin.wedTitle,
                                person: currentBulletin.preacher,
                                highlightCenter: true,
                              ),
                              _buildResponsiveWorshipRow(
                                isMobile: isMobile,
                                order: '찬양',
                                content: currentBulletin.wedHymn2,
                                person: '다함께',
                              ),
                              _buildResponsiveWorshipRow(
                                isMobile: isMobile,
                                order: '축도',
                                content: '',
                                person: currentBulletin.presider,
                              ),
                            ],
                          ),
                          const Divider(height: 1),
                          ExpansionTile(
                            title: const Text(
                              '예배 시간 및 섬기는 이들 안내',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
            ),
          );
        },
      ),
    );
  }
}