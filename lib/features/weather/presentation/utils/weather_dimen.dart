/// 模块：天气页面尺寸常量（presentation/utils）
/// 作用：集中管理卡片圆角、间距等视觉节奏，避免散落魔法数字。
/// 依赖：纯 Dart。
library;

class WeatherDimen {
  const WeatherDimen._();

  static const double pageHorizontal = 15;
  static const double sectionGap = 20;
  static const double largeSectionGap = 30;
  static const double cardInnerGap = 15;

  static const double singleDayForecastHeight = 90;
  static const double aqiChartHeight = 120;
  static const double hourChartHeight = 190;
  static const double dayDetailHeightRatio = 0.6;
}
