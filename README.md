# Quản lý bán hàng cửa hàng tiện lợi

Bài tập nhóm môn Cơ sở dữ liệu + Lập trình hướng đối tượng.

- **Hệ quản trị CSDL:** Microsoft SQL Server 2019 / 2022
- **Công cụ:** SQL Server Management Studio (SSMS) 19+ hoặc Azure Data Studio
- **Tên CSDL:** `QLCuaHangTienLoi`

## Cấu trúc thư mục

| File | Nội dung |
|---|---|
| `sql/01_TaoCSDL_Bang.sql` | Tạo CSDL, 11 bảng, khóa chính, khóa ngoại, CHECK, UNIQUE, DEFAULT, chỉ mục |
| `sql/02_View_Function_Trigger_Procedure.sql` | 4 function, 4 view, 3 trigger, 6 stored procedure |
| `sql/03_DuLieuMau.sql` | Dữ liệu mẫu: 6 nhân viên, 8 khách hàng, 20 sản phẩm, 6 phiếu nhập, 20 hóa đơn |
| `sql/04_TruyVan.sql` | 25 câu truy vấn từ cơ bản đến nâng cao + ví dụ INSERT/UPDATE/DELETE |
| `sql/05_KiemThu_NghiepVu.sql` | 7 kịch bản kiểm thử nghiệp vụ (bán hàng, vượt tồn kho, hủy hóa đơn, nhập hàng...) |

## Cách chạy

Mở từng file trong SSMS và nhấn **Execute (F5)** theo đúng thứ tự:

```
01 -> 02 -> 03 -> 04 -> 05
```

File 01 sẽ xóa và tạo lại CSDL, nên muốn làm lại từ đầu chỉ cần chạy lại từ file 01.
File 04 và 05 không làm thay đổi dữ liệu (phần cập nhật được ROLLBACK).

## Các bảng

`ChucVu`, `NhanVien`, `HangThanhVien`, `KhachHang`, `DanhMuc`, `NhaCungCap`, `SanPham`,
`PhieuNhap`, `ChiTietPhieuNhap`, `HoaDon`, `ChiTietHoaDon`

## Điểm nổi bật

- CSDL đạt **dạng chuẩn 3 (3NF)**: tổng tiền hóa đơn, điểm tích lũy, hạng thành viên không lưu mà được tính qua view.
- **Tồn kho tự động** bằng trigger: nhập hàng cộng tồn, bán hàng trừ tồn (chặn khi không đủ hàng), hủy hóa đơn hoàn tồn.
- **Hạng thành viên** (Thường / Bạc / Vàng / Kim cương) tự xác định theo điểm, mức giảm giá áp tự động khi lập hóa đơn bằng số điện thoại khách.
- Lưu **giá bán tại thời điểm bán** và **mức giảm tại thời điểm bán** để hóa đơn cũ không bị đổi khi giá thay đổi.

## Thành viên nhóm

| Thành viên | MSSV | Phụ trách |
|---|---|---|
| Khuê | N24DCAT042 | Phân tích, thiết kế CSDL, chuẩn hóa, bảng + ràng buộc, dữ liệu mẫu, truy vấn I–III |
| *(Thành viên 2)* | *(MSSV)* | View, function, trigger, procedure, truy vấn IV–VI, kịch bản kiểm thử |
