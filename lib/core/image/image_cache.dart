// 模块：图片缓存策略（core/image）
// 作用：集中定义网络图片的缓存命名、过期时间与清理入口，供各业务模块复用。
// 依赖：extended_image（含 extended_image_library 的内存/磁盘缓存实现）。
// 为什么放在 core：图片缓存是基础设施，不是某个业务的私有能力——
//   「我的」页面要能清理缓存、信息流要能配置缓存名，二者都只应该依赖 core。
// 缓存分层（extended_image 提供）：
//   内存缓存：按 [thumbCacheName]/[fullCacheName] 命名，来回切页面可秒开；
//   磁盘缓存：写系统临时目录 cacheimage/，冷启动仍可命中（内置 Image.network 没有这一层）；
//   过期策略：[thumbMaxAge]/[fullMaxAge] 到期后重新拉取，避免长期展示旧图。
// 降级行为：extended_image 的磁盘缓存实现内部 try/catch，
//   在 Web 或缺少文件系统权限的环境下只会返回 false，不会抛异常。

import 'package:extended_image/extended_image.dart';

/// 图片缓存配置与清理入口。
class ImageCachePolicy {
  const ImageCachePolicy._();

  /// 列表缩略图缓存名。
  static const String thumbCacheName = 'image-thumb';

  /// 缩略图过期时间（列表更新频繁，7 天足够）。
  static const Duration thumbMaxAge = Duration(days: 7);

  /// 预览原图缓存名：与缩略图分开命名，可按需单独清理。
  static const String fullCacheName = 'image-full';

  /// 原图过期时间（重新下载成本高，留久一点）。
  static const Duration fullMaxAge = Duration(days: 30);

  /// 清空全部图片缓存（内存 + 磁盘）。
  ///
  /// 返回值表示磁盘缓存是否清理成功：Web 或权限受限环境会返回 false，
  /// 此时内存缓存已被清理，不影响主流程。
  static Future<bool> clearAll() async {
    clearMemoryImageCache(thumbCacheName);
    clearMemoryImageCache(fullCacheName);
    // 再清一次全部内存缓存：兜住其它页面/其它缓存名留下的图片。
    clearMemoryImageCache();
    return clearDiskCachedImages();
  }
}
