/// 模块：城市搜索栏（presentation/widgets）
/// 作用：搜索页顶部输入框 + 取消/搜索按钮。
/// 依赖：Flutter。
library;

import 'package:flutter/material.dart';

class CitySearchBar extends StatefulWidget {
  const CitySearchBar({
    super.key,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCancel,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;

  @override
  State<CitySearchBar> createState() => _CitySearchBarState();
}

class _CitySearchBarState extends State<CitySearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final hasText = value.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
    widget.onChanged(value);
  }

  void _clear() {
    _controller.clear();
    _handleChanged('');
  }

  void _handleAction() {
    if (_hasText) {
      widget.onSubmitted(_controller.text);
    } else {
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _handleChanged,
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                hintText: '搜索城市天气',
                hintStyle: const TextStyle(color: Color(0xFF999999)),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _hasText
                    ? IconButton(
                        onPressed: _clear,
                        icon: const Icon(Icons.clear, color: Colors.grey),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF2F3F5),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _handleAction,
            child: Text(
              _hasText ? '搜索' : '取消',
              style: const TextStyle(
                color: Color(0xFF1E88E5),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
