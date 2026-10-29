# Fastlane 依赖声明：CI 与本地共用同一份版本约束。
# 约定：Gemfile.lock 必须提交到 Git（保证 CI 与本地解析出完全一致的 fastlane 版本）。
# 用法：bundle install && bundle exec fastlane android qa
source "https://rubygems.org"

# 版本下限只做"别装到太老的版本"的兜底；真正锁定的版本是 Gemfile.lock（必须提交）。
gem "fastlane", ">= 2.220", "< 3.0"

# 把 fastlane/Pluginfile 里的插件一并纳入 Bundler 管理（见该文件）。
eval_gemfile "fastlane/Pluginfile"
