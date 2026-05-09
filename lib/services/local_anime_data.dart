import '../models/anime.dart';

class LocalAnimeData {
  // 国内可访问的示例视频 (字节跳动CDN)
  static const List<String> _videoUrls = [
    'https://sf1-cdn-tos.huoshanstatic.com/obj/media-fe/xgplayer_doc_video/mp4/xgplayer-demo-720p.mp4',
    'https://sf1-cdn-tos.huoshanstatic.com/obj/media-fe/xgplayer_doc_video/mp4/xgplayer-demo-360p.mp4',
    'https://sf1-hscdn-tos.pstatp.com/obj/media-fe/xgplayer_doc_video/hls/xgplayer-demo.m3u8',
  ];

  static List<Episode> _eps(String baseName, int count) {
    return List.generate(count, (i) => Episode(
      title: '第${i + 1}集',
      url: _videoUrls[i % _videoUrls.length],
    ));
  }

  static final List<Anime> _allAnime = [
    Anime(
      id: '101', title: '进击的巨人 最终季', cover: '',
      description: '艾伦·耶格尔与同伴们为了自由而战的故事。在墙壁之内的世界中，人类面临着巨人的威胁，而真相远比想象中更加残酷。',
      type: '日韩动漫', year: '2023', status: '已完结', rating: '9.0',
      genres: ['热血', '动作', '奇幻'], updateInfo: '完结',
      episodes: _eps('进击的巨人', 16),
    ),
    Anime(
      id: '102', title: '鬼灭之刃 柱训练篇', cover: '',
      description: '灶门炭治郎为了拯救变成鬼的妹妹，加入了鬼杀队。在与各种鬼的战斗中不断成长，向着最终的敌人发起挑战。',
      type: '日韩动漫', year: '2024', status: '已完结', rating: '8.5',
      genres: ['热血', '动作', '奇幻'], updateInfo: '2024年新番',
      episodes: _eps('鬼灭之刃', 8),
    ),
    Anime(
      id: '103', title: '咒术回战 第二季', cover: '',
      description: '虎杖悠仁吞下了诅咒之王两面宿傩的手指，成为了宿傩的容器。在咒术高专中，他与伙伴们一起对抗强大的咒灵。',
      type: '日韩动漫', year: '2023', status: '已完结', rating: '8.8',
      genres: ['热血', '动作', '奇幻'], updateInfo: '完结',
      episodes: _eps('咒术回战', 23),
    ),
    Anime(
      id: '104', title: '间谍过家家 第二季', cover: '',
      description: '间谍黄昏为了执行任务，组成了一个临时家庭。然而他的女儿是超能力者，妻子是杀手，三人都在隐藏自己的秘密。',
      type: '日韩动漫', year: '2023', status: '已完结', rating: '8.6',
      genres: ['搞笑', '日常', '动作'], updateInfo: '完结',
      episodes: _eps('间谍过家家', 12),
    ),
    Anime(
      id: '105', title: '葬送的芙莉莲', cover: '',
      description: '魔王讨伐成功后，精灵魔法使芙莉莲开始了新的旅程。在与曾经的同伴们的回忆中，她逐渐理解了人类的情感。',
      type: '日韩动漫', year: '2023', status: '已完结', rating: '9.2',
      genres: ['奇幻', '冒险', '治愈'], updateInfo: '2023年度最佳',
      episodes: _eps('葬送的芙莉莲', 28),
    ),
    Anime(
      id: '106', title: '排球少年!! 垃圾场的决战', cover: '',
      description: '日向翔阳和影山飞雄带领乌野高中排球部，在全国大赛中与音驹高中展开了一场激动人心的对决。',
      type: '日韩动漫', year: '2024', status: '已上映', rating: '8.9',
      genres: ['运动', '热血', '友情'], updateInfo: '2024剧场版',
      episodes: _eps('排球少年', 1),
    ),
    Anime(
      id: '107', title: '迷宫饭', cover: '',
      description: '为了救回被龙吞噬的妹妹，冒险者莱欧斯一行人深入迷宫。为了在迷宫中生存，他们开始烹饪魔物为食。',
      type: '日韩动漫', year: '2024', status: '连载中', rating: '8.3',
      genres: ['奇幻', '美食', '冒险'], updateInfo: '2024年新番',
      episodes: _eps('迷宫饭', 24),
    ),
    Anime(
      id: '108', title: '药屋少女的呢喃', cover: '',
      description: '在后宫中工作的药师猫猫，凭借自己的药学知识和推理能力，解决了各种神秘事件，逐渐卷入宫廷的权力斗争。',
      type: '日韩动漫', year: '2024', status: '连载中', rating: '8.4',
      genres: ['推理', '宫廷', '治愈'], updateInfo: '2024年新番',
      episodes: _eps('药屋少女', 24),
    ),
    Anime(
      id: '109', title: '一拳超人', cover: '',
      description: '埼玉是一个拥有超强实力的英雄，一拳就能击败任何敌人。然而，这种无敌的力量却让他感到无比的空虚。',
      type: '日韩动漫', year: '2025', status: '连载中', rating: '8.1',
      genres: ['热血', '搞笑', '动作'], updateInfo: '2025年新番',
      episodes: _eps('一拳超人', 12),
    ),
    Anime(
      id: '110', title: '我的英雄学院 第七季', cover: '',
      description: '在超能力社会中，无能力的少年绿谷出久继承了最强英雄的能力，朝着成为最伟大英雄的目标不断前进。',
      type: '日韩动漫', year: '2024', status: '连载中', rating: '8.0',
      genres: ['热血', '动作', '校园'], updateInfo: '2024年新番',
      episodes: _eps('我的英雄学院', 21),
    ),
    Anime(
      id: '111', title: '电锯人', cover: '',
      description: '电次是一个背负着父亲债务的少年，与链锯恶魔波奇塔合体后成为了电锯人，加入了公安恶魔猎人组织。',
      type: '日韩动漫', year: '2022', status: '已完结', rating: '8.2',
      genres: ['热血', '动作', '黑暗'], updateInfo: '完结',
      episodes: _eps('电锯人', 12),
    ),
    Anime(
      id: '112', title: '铃芽之旅', cover: '',
      description: '少女铃芽遇到了关闭灾难之门的青年草太，两人一起踏上了一段穿越日本的旅程，关闭各地的灾难之门。',
      type: '日韩动漫', year: '2022', status: '已上映', rating: '8.7',
      genres: ['奇幻', '冒险', '爱情'], updateInfo: '新海诚作品',
      episodes: _eps('铃芽之旅', 1),
    ),
    Anime(
      id: '113', title: 'BLEACH 千年血战篇', cover: '',
      description: '黑崎一护再次拿起斩魄刀，面对来自无形帝国的灭却师军团，展开了一场关乎尸魂界存亡的战斗。',
      type: '日韩动漫', year: '2024', status: '连载中', rating: '8.6',
      genres: ['热血', '动作', '奇幻'], updateInfo: '2024年新番',
      episodes: _eps('BLEACH', 13),
    ),
    Anime(
      id: '114', title: '蓝色监狱', cover: '',
      description: '为了培养出世界上最强大的前锋，日本足球协会启动了"蓝色监狱"计划，300名年轻的前锋在这里展开残酷的竞争。',
      type: '日韩动漫', year: '2023', status: '已完结', rating: '8.0',
      genres: ['运动', '热血'], updateInfo: '完结',
      episodes: _eps('蓝色监狱', 24),
    ),
    Anime(
      id: '115', title: '孤独摇滚', cover: '',
      description: '极度社恐的后藤独在高中生活中通过乐队找到了自己的位置，与性格迥异的成员们一起追逐音乐梦想。',
      type: '日韩动漫', year: '2022', status: '已完结', rating: '8.9',
      genres: ['音乐', '搞笑', '校园'], updateInfo: '完结',
      episodes: _eps('孤独摇滚', 12),
    ),
    Anime(
      id: '116', title: '天国大魔境', cover: '',
      description: '在文明崩塌后的日本，少年�的和神秘少女一起踏上了寻找"天国"的旅程，同时还有另一群孩子在封闭设施中生活的故事。',
      type: '日韩动漫', year: '2023', status: '已完结', rating: '8.3',
      genres: ['科幻', '冒险', '悬疑'], updateInfo: '完结',
      episodes: _eps('天国大魔境', 13),
    ),
    Anime(
      id: '117', title: '我推的孩子 第二季', cover: '',
      description: '转世为偶像的孩子星野爱久爱�的，在演艺圈中追寻真相，同时面对着前世与今生的复杂情感。',
      type: '日韩动漫', year: '2024', status: '已完结', rating: '8.1',
      genres: ['偶像', '悬疑'], updateInfo: '完结',
      episodes: _eps('我推的孩子', 13),
    ),
    Anime(
      id: '118', title: '葬送的芙莉莲 第二季', cover: '',
      description: '芙莉莲继续她的旅程，在回忆与现实交织中，探索魔法的奥秘和人类情感的深度。',
      type: '日韩动漫', year: '2025', status: '连载中', rating: '9.0',
      genres: ['奇幻', '冒险', '治愈'], updateInfo: '2025年新番',
      episodes: _eps('芙莉莲S2', 12),
    ),
    Anime(
      id: '119', title: '怪兽8号', cover: '',
      description: '日比野卡夫卡在怪兽防卫队中努力实现梦想，却意外获得了变身怪兽的能力，在人类与怪兽之间寻找自己的道路。',
      type: '日韩动漫', year: '2024', status: '已完结', rating: '7.8',
      genres: ['热血', '动作', '科幻'], updateInfo: '完结',
      episodes: _eps('怪兽8号', 12),
    ),
    Anime(
      id: '120', title: '擅长逃跑的殿下', cover: '',
      description: '北条时行在镰仓幕府灭亡后，凭借着逃跑的天赋和伙伴们的帮助，在乱世中求生并试图复兴家族。',
      type: '日韩动漫', year: '2024', status: '连载中', rating: '7.9',
      genres: ['历史', '冒险', '搞笑'], updateInfo: '2024年新番',
      episodes: _eps('擅长逃跑的殿下', 12),
    ),
  ];

  static List<Anime> getRecommend() {
    final list = List<Anime>.from(_allAnime);
    list.shuffle();
    return list.take(5).toList();
  }

  static List<Anime> getLatest() {
    return List<Anime>.from(_allAnime);
  }

  static List<Anime> search(String keyword) {
    final lower = keyword.toLowerCase();
    return _allAnime.where((a) =>
      a.title.toLowerCase().contains(lower) ||
      a.description.toLowerCase().contains(lower) ||
      a.genres.any((g) => g.toLowerCase().contains(lower))
    ).toList();
  }

  static List<Anime> getByCategory(String category) {
    return _allAnime.where((a) =>
      a.genres.contains(category) || a.year == category
    ).toList();
  }

  static Anime? getById(String id) {
    try {
      return _allAnime.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
