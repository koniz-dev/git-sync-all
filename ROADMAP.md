# Roadmap

## v0.1.0 — Publish

- [x] Tách command thành executable `bin/git-sync-all`.
- [x] Thêm installer, Bash/Zsh completion, README và MIT License.
- [x] Thêm `--help`, `--version`, `--dry-run`.
- [x] Kiểm tra cú pháp và smoke test local.
- [x] Commit và publish repository `koniz-dev/git-sync-all`.
- [x] Tạo GitHub Release `v0.1.0` với release notes ngắn.

Publish từ một terminal đã đăng nhập GitHub:

```bash
cd /Users/nguyenanhkiet/Playground/git-sync-all
git add .
git commit -m "Initial release"
gh repo create git-sync-all --public --source=. --remote=origin --push
gh release create v0.1.0 --title "v0.1.0" --generate-notes
```

## v0.2.0 — Reliability

- [x] Thêm test tự động cho repository thường, branch thiếu, remote thiếu và submodule lồng nhau.
- [x] Chạy ShellCheck trong GitHub Actions.
- [x] Thêm CI chạy `bash -n` và smoke test.
- [x] Bổ sung cờ `--rebase` hoặc cấu hình pull strategy rõ ràng.

## v0.3.0 — Cross-platform support

Mục tiêu là bảo đảm command hoạt động trên macOS, Linux và Windows, thay vì
chỉ dựa vào Bash có sẵn.

- [x] Xác định ma trận hỗ trợ chính thức: macOS, Ubuntu LTS và Windows 11.
- [x] Giữ bản Bash cho macOS/Linux và Git Bash/WSL trên Windows.
- [x] Thêm installer PowerShell (`install.ps1`) cho Windows native.
- [x] Đảm bảo `git-sync-all` được nhận là Git subcommand từ PATH trên Windows.
- [x] Kiểm tra các dependency và đường dẫn tạm thay cho các giả định Unix-only
  như `mktemp`, `sed`, `wc` và `tr`.
- [x] Nếu Git for Windows không đủ tương thích, tách phần điều phối sang
  PowerShell hoặc phát hành binary đa nền tảng.
- [x] Thêm GitHub Actions matrix chạy smoke test trên `macos-latest`,
  `ubuntu-latest` và `windows-latest`.
- [x] Ghi rõ trong README các môi trường đã kiểm thử và các fallback được hỗ trợ
  (Git Bash/WSL trên Windows).

## v0.4.0 — Distribution

- [x] Tạo Homebrew tap và formula `git-sync-all`.
- [x] Cài completion tự động qua installer (có tùy chọn opt-in).
- [x] Thêm uninstall script.
