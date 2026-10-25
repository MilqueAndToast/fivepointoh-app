import 'package:flutter/material.dart';

/// Vector contour traced from the user's dnd_silhouette.png reference.
/// Reference proportions are preserved, with no backpack, cape, or sword.
class EquipmentFigure {
  static const left = 190.0, width = 730.0, height = 1402.0;
  static final silhouette = Path()
    ..moveTo(579, 15)
    ..lineTo(613, 41)
    ..lineTo(646, 81)
    ..lineTo(660, 144)
    ..lineTo(680, 189)
    ..lineTo(677, 201)
    ..lineTo(660, 217)
    ..lineTo(660, 225)
    ..lineTo(679, 234)
    ..lineTo(680, 248)
    ..lineTo(705, 265)
    ..quadraticBezierTo(719, 283, 725, 317)
    ..quadraticBezierTo(725, 358, 728, 386)
    ..quadraticBezierTo(733, 412, 742, 428)
    ..lineTo(753, 446)
    ..lineTo(753, 470)
    ..lineTo(759, 479)
    ..lineTo(774, 486)
    ..lineTo(782, 503)
    ..lineTo(791, 502)
    ..lineTo(794, 505)
    ..lineTo(798, 535)
    ..lineTo(817, 605)
    ..lineTo(825, 619)
    ..lineTo(825, 633)
    ..lineTo(829, 639)
    ..lineTo(827, 651)
    ..lineTo(836, 680)
    ..lineTo(835, 694)
    ..lineTo(826, 708)
    ..lineTo(815, 717)
    ..lineTo(803, 720)
    ..lineTo(792, 720)
    ..lineTo(785, 715)
    ..lineTo(785, 708)
    ..lineTo(776, 704)
    ..lineTo(769, 685)
    ..lineTo(764, 681)
    ..lineTo(760, 669)
    ..lineTo(763, 653)
    ..lineTo(772, 642)
    ..lineTo(771, 620)
    ..lineTo(736, 572)
    ..lineTo(716, 554)
    ..lineTo(718, 539)
    ..lineTo(715, 531)
    ..lineTo(707, 527)
    ..lineTo(702, 519)
    ..lineTo(702, 493)
    ..lineTo(688, 485)
    ..lineTo(685, 458)
    ..lineTo(681, 451)
    ..lineTo(674, 451)
    ..lineTo(671, 489)
    ..lineTo(677, 492)
    ..lineTo(681, 526)
    ..lineTo(679, 536)
    ..lineTo(698, 566)
    ..lineTo(695, 585)
    ..lineTo(708, 622)
    ..quadraticBezierTo(724, 693, 741, 738)
    ..quadraticBezierTo(748, 752, 749, 760)
    ..quadraticBezierTo(744, 767, 728, 774)
    ..quadraticBezierTo(721, 817, 715, 844)
    ..lineTo(711, 878)
    ..lineTo(725, 922)
    ..lineTo(719, 952)
    ..lineTo(722, 971)
    ..lineTo(717, 979)
    ..lineTo(717, 986)
    ..lineTo(721, 989)
    ..lineTo(722, 996)
    ..lineTo(733, 1003)
    ..lineTo(733, 1031)
    ..lineTo(748, 1066)
    ..lineTo(748, 1071)
    ..lineTo(736, 1081)
    ..lineTo(723, 1079)
    ..lineTo(721, 1087)
    ..lineTo(718, 1142)
    ..lineTo(724, 1153)
    ..lineTo(724, 1160)
    ..lineTo(719, 1168)
    ..lineTo(719, 1176)
    ..lineTo(726, 1185)
    ..lineTo(722, 1205)
    ..lineTo(732, 1213)
    ..lineTo(733, 1223)
    ..lineTo(767, 1259)
    ..lineTo(787, 1270)
    ..lineTo(788, 1275)
    ..lineTo(812, 1278)
    ..lineTo(824, 1283)
    ..lineTo(830, 1291)
    ..lineTo(831, 1299)
    ..lineTo(835, 1301)
    ..lineTo(836, 1311)
    ..lineTo(815, 1318)
    ..lineTo(777, 1319)
    ..lineTo(733, 1312)
    ..lineTo(707, 1299)
    ..lineTo(679, 1305)
    ..lineTo(637, 1297)
    ..lineTo(635, 1276)
    ..lineTo(639, 1273)
    ..lineTo(638, 1260)
    ..lineTo(647, 1225)
    ..lineTo(647, 1217)
    ..lineTo(641, 1205)
    ..lineTo(649, 1191)
    ..lineTo(649, 1181)
    ..lineTo(639, 1169)
    ..lineTo(643, 1141)
    ..lineTo(626, 1083)
    ..lineTo(606, 1082)
    ..lineTo(602, 1078)
    ..lineTo(608, 1039)
    ..lineTo(606, 1006)
    ..lineTo(615, 1000)
    ..lineTo(609, 976)
    ..lineTo(621, 958)
    ..lineTo(623, 936)
    ..lineTo(623, 929)
    ..lineTo(610, 910)
    ..lineTo(615, 878)
    ..lineTo(586, 791)
    ..lineTo(570, 792)
    ..lineTo(568, 782)
    ..lineTo(560, 781)
    ..lineTo(558, 789)
    ..lineTo(551, 790)
    ..lineTo(548, 799)
    ..lineTo(525, 845)
    ..lineTo(504, 875)
    ..lineTo(501, 909)
    ..lineTo(479, 931)
    ..lineTo(475, 948)
    ..lineTo(479, 976)
    ..lineTo(462, 991)
    ..lineTo(462, 1003)
    ..lineTo(469, 1012)
    ..lineTo(460, 1038)
    ..lineTo(459, 1087)
    ..lineTo(455, 1091)
    ..lineTo(445, 1088)
    ..lineTo(429, 1091)
    ..lineTo(423, 1112)
    ..lineTo(405, 1148)
    ..lineTo(407, 1170)
    ..lineTo(394, 1185)
    ..lineTo(398, 1213)
    ..lineTo(387, 1226)
    ..lineTo(390, 1247)
    ..lineTo(386, 1252)
    ..lineTo(386, 1260)
    ..lineTo(391, 1285)
    ..lineTo(391, 1308)
    ..lineTo(381, 1319)
    ..lineTo(376, 1319)
    ..lineTo(379, 1349)
    ..lineTo(370, 1360)
    ..lineTo(340, 1370)
    ..lineTo(293, 1368)
    ..lineTo(282, 1363)
    ..lineTo(275, 1352)
    ..lineTo(275, 1340)
    ..lineTo(279, 1337)
    ..lineTo(281, 1323)
    ..lineTo(296, 1303)
    ..lineTo(316, 1254)
    ..lineTo(316, 1239)
    ..lineTo(321, 1232)
    ..lineTo(321, 1223)
    ..lineTo(316, 1215)
    ..lineTo(315, 1205)
    ..lineTo(327, 1189)
    ..lineTo(327, 1177)
    ..lineTo(321, 1166)
    ..lineTo(321, 1158)
    ..lineTo(331, 1141)
    ..lineTo(330, 1095)
    ..lineTo(334, 1066)
    ..lineTo(321, 1070)
    ..lineTo(310, 1060)
    ..lineTo(309, 1055)
    ..lineTo(335, 1012)
    ..lineTo(340, 985)
    ..lineTo(344, 981)
    ..lineTo(353, 980)
    ..lineTo(352, 965)
    ..lineTo(369, 951)
    ..lineTo(367, 929)
    ..lineTo(388, 911)
    ..lineTo(391, 902)
    ..lineTo(395, 877)
    ..lineTo(413, 855)
    ..lineTo(416, 812)
    ..quadraticBezierTo(418, 786, 419, 761)
    ..quadraticBezierTo(398, 756, 390, 749)
    ..quadraticBezierTo(395, 747, 397, 743)
    // Continuous tunic side beneath the removed hip pouch.
    ..quadraticBezierTo(420, 659, 451, 567)
    ..quadraticBezierTo(463, 539, 477, 526)
    ..lineTo(477, 510)
    // Remove the leftover flap under the arm, following the torso edge.
    ..lineTo(477, 489)
    ..quadraticBezierTo(480, 465, 469, 440)
    ..quadraticBezierTo(461.22587362, 424.93763014, 456.28473354, 412)
    ..lineTo(445, 411)
    ..lineTo(438, 443)
    ..lineTo(422, 460)
    ..lineTo(424, 478)
    ..lineTo(414, 489)
    ..lineTo(417, 510)
    ..lineTo(407, 524)
    ..lineTo(410, 540)
    ..lineTo(397, 562)
    ..lineTo(384, 604)
    ..lineTo(384, 640)
    ..lineTo(397, 661)
    ..lineTo(399, 707)
    ..lineTo(386, 711)
    ..lineTo(389, 722)
    ..lineTo(387, 728)
    ..lineTo(374, 728)
    // Close the outline around the exposed arm instead of the trailing cape.
    ..quadraticBezierTo(356, 724, 343, 714)
    ..quadraticBezierTo(325, 706, 323, 681)
    ..lineTo(330, 639)
    ..lineTo(323, 626)
    ..lineTo(328, 609)
    ..lineTo(325, 581)
    ..lineTo(317, 524)
    ..lineTo(329, 508)
    ..lineTo(334, 482)
    ..quadraticBezierTo(357, 469, 354, 459)
    ..quadraticBezierTo(349, 447, 354, 438)
    ..quadraticBezierTo(366, 423, 369, 402)
    ..quadraticBezierTo(377, 383, 378, 366)
    ..lineTo(383, 333)
    ..quadraticBezierTo(385, 297, 400, 268)
    ..quadraticBezierTo(417, 240, 440, 224)
    ..lineTo(461, 214)
    ..lineTo(463, 188)
    ..lineTo(463, 181)
    ..lineTo(475, 162)
    ..lineTo(475, 134)
    ..lineTo(493, 109)
    ..lineTo(511, 63)
    ..lineTo(530, 43)
    ..close();

  static Path polygon(List<double> xy) {
    final path = Path()..moveTo(xy[0], xy[1]);
    for (var i = 2; i < xy.length; i += 2) {
      path.lineTo(xy[i], xy[i + 1]);
    }
    return path..close();
  }

  static Path zone(List<double> xy) =>
      Path.combine(PathOperation.intersect, silhouette, polygon(xy));
  static Path rect(double x, double y, double w, double h) => Path.combine(
    PathOperation.intersect,
    silhouette,
    Path()..addRect(Rect.fromLTWH(x, y, w, h)),
  );
  static final Map<int, Path> regions = _partition();
  static Path get hood => regions[4]!;
  static Path get band => regions[5]!;
  static Path get eye => regions[6]!;
  static Path get shoulders => regions[7]!;
  static Path get neck => regions[8]!;
  static Path get chest => regions[9]!;
  static Path get belt => regions[10]!;
  static Path get wrists => regions[11]!;
  static Path get hands => regions[12]!;
  static Path get feet => regions[13]!;
  static Path get leftRing => regions[14]!;
  static Path get rightRing => regions[15]!;
  static Path get legs => regions[16]!;

  // Define the torso explicitly so gaps between limb masks cannot become
  // stray Chest targets. The remaining upper sleeves belong to Shoulders.
  // Keep compound paths intact so holes remain holes during hit tests.
  static Map<int, Path> _partition() {
    final result = <int, Path>{};
    var occupied = Path();
    void claim(int id, Path shape) {
      final clipped = Path.combine(PathOperation.intersect, silhouette, shape);
      final available = Path.combine(
        PathOperation.difference,
        clipped,
        occupied,
      );
      result[id] = available;
      occupied = Path.combine(PathOperation.union, occupied, available);
    }

    Path rectangle(double x, double y, double w, double h) =>
        Path()..addRect(Rect.fromLTWH(x, y, w, h));

    // Both face targets stop at the same contour as the hood opening seam.
    // The upper band and eye area partition that opening without taking hood.
    claim(
      5,
      Path.combine(
        PathOperation.intersect,
        faceOpening,
        Path()
          ..moveTo(450, 167)
          ..quadraticBezierTo(571, 145, 700, 170)
          ..lineTo(700, 0)
          ..lineTo(450, 0)
          ..close(),
      ),
    );
    claim(6, faceOpening);
    // End Head at the collar's upper edge, then claim the whole band below
    // it as Neck. No hood fragments can surround the collar's lower edge.
    claim(
      4,
      _hoodHem()
        ..lineTo(740, 217)
        ..lineTo(740, 0)
        ..lineTo(440, 0)
        ..lineTo(440, 214)
        ..close(),
    );
    claim(
      8,
      _collarHem()
        ..lineTo(740, 248)
        ..lineTo(740, 0)
        ..lineTo(440, 0)
        ..lineTo(440, 215)
        ..quadraticBezierTo(445, 225, 455, 230)
        ..close(),
    );

    // Rings cover the fingers; the remainder of each glove selects Hands.
    claim(14, Path()..addOval(const Rect.fromLTWH(337, 688, 57, 43)));
    claim(15, Path()..addOval(const Rect.fromLTWH(773, 682, 57, 43)));
    claim(
      12,
      Path()
        ..addPath(
          _leftGloveCuff()
            ..lineTo(410, 626)
            ..lineTo(402, 710)
            ..lineTo(395, 738)
            ..lineTo(290, 738)
            ..lineTo(290, 626)
            ..close(),
          Offset.zero,
        )
        ..addPath(
          _rightGloveCuff()
            ..lineTo(850, 630)
            ..lineTo(873, 738)
            ..lineTo(741, 738)
            ..lineTo(741, 632)
            ..close(),
          Offset.zero,
        ),
    );
    // Hit regions and visible seams share the same complete cuff contours.
    claim(
      11,
      Path()
        ..addPath(
          _leftBracerCuff()
            ..lineTo(413, 540)
            ..lineTo(395, 640)
            ..lineTo(290, 640)
            ..lineTo(290, 524)
            ..close(),
          Offset.zero,
        )
        ..addPath(
          _rightBracerCuff()
            ..lineTo(860, 470)
            ..lineTo(873, 645)
            ..lineTo(750, 645)
            ..lineTo(710, 558)
            ..close(),
          Offset.zero,
        ),
    );
    claim(
      13,
      Path()
        ..addPath(
          _leftBootCuff()
            ..lineTo(550, 1008)
            ..lineTo(550, height)
            ..lineTo(0, height)
            ..lineTo(0, 984)
            ..close(),
          Offset.zero,
        )
        ..addPath(
          _rightBootCuff()
            ..lineTo(1122, 1003)
            ..lineTo(1122, height)
            ..lineTo(550, height)
            ..lineTo(550, 1006)
            ..close(),
          Offset.zero,
        ),
    );
    claim(10, rectangle(460, 482, 221, 52));
    claim(
      16,
      polygon([
        450,
        528,
        700,
        528,
        741,
        738,
        1122,
        738,
        1122,
        height,
        0,
        height,
        0,
        738,
        395,
        738,
      ]),
    );

    // A continuous neckline and curved armholes keep Chest on the torso.
    // The side curves meet the rounded shoulder caps and the underarms.
    claim(
      9,
      _collarHem()
        ..cubicTo(656, 254, 640, 269, 640, 291)
        ..quadraticBezierTo(645, 312, 669, 329)
        ..quadraticBezierTo(679, 337, 690, 341)
        ..cubicTo(687, 385, 674, 423, 674, 451)
        ..lineTo(671, 489)
        ..lineTo(477, 489)
        ..quadraticBezierTo(480, 465, 469, 440)
        ..quadraticBezierTo(461.22587362, 424.93763014, 456.28473354, 412)
        ..quadraticBezierTo(451.05646841, 398.31057623, 449, 387)
        ..quadraticBezierTo(440, 347, 445, 314)
        ..quadraticBezierTo(476, 294, 486, 275)
        ..quadraticBezierTo(480, 248, 455, 230)
        ..close(),
    );
    claim(7, silhouette);
    return Map.unmodifiable(result);
  }

  // Trace the existing inner hood detail once for both painting and hit tests.
  static Path _hoodOpeningEdge() => Path()
    ..moveTo(592, 69)
    ..quadraticBezierTo(551, 98, 531, 119)
    ..quadraticBezierTo(513, 149, 494, 178)
    ..quadraticBezierTo(484, 190, 518, 205);

  static final faceOpening = _hoodOpeningEdge()
    ..quadraticBezierTo(579, 246, 641, 208)
    ..quadraticBezierTo(651, 202, 648, 183)
    ..quadraticBezierTo(643, 135, 626, 103)
    ..quadraticBezierTo(611, 80, 592, 69)
    ..close();

  static Path _hoodHem() => Path()
    ..moveTo(461, 214)
    ..cubicTo(499, 231, 527, 249, 560, 253)
    ..cubicTo(593, 257, 633, 242, 660, 217);

  static Path _collarHem() => Path()
    ..moveTo(455, 230)
    ..cubicTo(480, 281, 528, 315, 574, 312)
    ..cubicTo(620, 309, 663, 280, 680, 248);

  static Path _leftBracerCuff() => Path()
    ..moveTo(317, 524)
    ..quadraticBezierTo(360, 487, 408.125, 530);

  static Path _rightBracerCuff() => Path()
    ..moveTo(716.239, 554.215)
    ..lineTo(794.422, 508.163);

  static Path _leftGloveCuff() => Path()
    ..moveTo(323, 626)
    ..quadraticBezierTo(353, 616, 384, 626);

  static Path _rightGloveCuff() => Path()
    ..moveTo(771.545, 632)
    ..quadraticBezierTo(801, 621, 825, 630);

  static Path _leftBootCuff() => Path()
    ..moveTo(341, 984)
    ..quadraticBezierTo(404, 1012, 466, 1008);

  static Path _rightBootCuff() => Path()
    ..moveTo(606, 1006)
    ..quadraticBezierTo(664, 1023, 733, 1003);

  // Sparse seams identify the hood, belt, and boot cuffs.
  static final seams = Path()
    ..addPath(_hoodOpeningEdge(), Offset.zero)
    ..addPath(_hoodHem(), Offset.zero)
    ..addPath(_collarHem(), Offset.zero)
    ..moveTo(477, 489)
    ..quadraticBezierTo(530, 479, 580, 484)
    ..moveTo(638, 486)
    ..lineTo(674, 489)
    ..moveTo(480, 526)
    ..lineTo(582, 528)
    ..moveTo(638, 529)
    ..lineTo(680, 529)
    ..moveTo(612, 549)
    ..quadraticBezierTo(608, 657, 586, 766)
    ..quadraticBezierTo(543, 761, 506, 746)
    ..quadraticBezierTo(444, 721, 402, 747)
    ..moveTo(615, 629)
    ..lineTo(620, 769)
    ..quadraticBezierTo(672, 767, 713, 754)
    ..addPath(_leftBracerCuff(), Offset.zero)
    ..addPath(_leftGloveCuff(), Offset.zero)
    ..addPath(_rightBracerCuff(), Offset.zero)
    ..addPath(_rightGloveCuff(), Offset.zero)
    ..addPath(_leftBootCuff(), Offset.zero)
    ..addPath(_rightBootCuff(), Offset.zero);
  static final buckle = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(584, 480, 54, 53),
        const Radius.circular(7),
      ),
    );
}
