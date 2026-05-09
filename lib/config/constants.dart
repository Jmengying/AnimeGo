class AppConstants {
  static const String appName = 'AnimeGo';
  static const String animeApiBase = 'https://api.agemys.org/api';
  static const String animeListEndpoint = '/anime/list';
  static const String animeDetailEndpoint = '/anime/detail';
  static const String animeSearchEndpoint = '/search';
  static const String animePlayEndpoint = '/anime/play';
  static const String animeRecommendEndpoint = '/anime/recommend';

  static const List<String> categories = [
    '全部', '热血', '恋爱', '搞笑', '校园', '冒险',
    '奇幻', '科幻', '运动', '战争', '悬疑', '恐怖',
    '后宫', '治愈', '日常', '机战', '音乐', '美食',
  ];

  static const List<String> years = [
    '全部', '2026', '2025', '2024', '2023', '2022',
    '2021', '2020', '2019', '2018', '2017', '2016',
  ];

  static const List<String> statusList = ['全部', '连载中', '已完结'];
}
