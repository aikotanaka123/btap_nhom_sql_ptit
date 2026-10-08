/* ==========================================================================
   FILE 03 : Dữ liệu mẫu
   Lưu ý   : Chạy NGAY SAU file 01 và 02 (CSDL mới tạo) vì MaPN, MaHD là IDENTITY
             bắt đầu từ 1. Tồn kho KHÔNG nhập tay mà do trigger tự tính
             (nhập hàng -> cộng, bán -> trừ, hủy hóa đơn -> cộng lại).
   ========================================================================== */
USE QLCuaHangTienLoi;
GO
SET NOCOUNT ON;
GO

-- 1. Chức vụ ------------------------------------------------------------------
INSERT INTO ChucVu (MaCV, TenCV, LuongCoBan) VALUES
('CV01', N'Cửa hàng trưởng', 12000000),
('CV02', N'Thu ngân',         7000000),
('CV03', N'Nhân viên kho',    6500000);

-- 2. Nhân viên ----------------------------------------------------------------
INSERT INTO NhanVien (MaNV, HoTen, GioiTinh, NgaySinh, SoDienThoai, DiaChi, NgayVaoLam, MaCV, DangLamViec) VALUES
('NV01', N'Nguyễn Văn An',    N'Nam', '1990-03-12', '0901234567', N'Gò Vấp, TP.HCM',     '2023-01-05', 'CV01', 1),
('NV02', N'Trần Thị Bích',    N'Nữ',  '2001-07-20', '0912345678', N'Quận 12, TP.HCM',    '2024-03-01', 'CV02', 1),
('NV03', N'Lê Hoàng Cường',   N'Nam', '2002-11-02', '0923456789', N'Bình Thạnh, TP.HCM', '2024-06-15', 'CV02', 1),
('NV04', N'Phạm Minh Đức',    N'Nam', '1998-05-30', '0934567890', N'Gò Vấp, TP.HCM',     '2023-09-10', 'CV03', 1),
('NV05', N'Võ Thị Hạnh',      N'Nữ',  '2003-02-14', '0945678901', N'Phú Nhuận, TP.HCM',  '2025-02-01', 'CV02', 1),
('NV06', N'Đặng Quốc Huy',    N'Nam', '1999-08-08', '0956789012', N'Tân Bình, TP.HCM',   '2023-05-20', 'CV02', 0); -- đã nghỉ việc

-- 3. Hạng thành viên (1 điểm = 10.000đ đã chi) --------------------------------
INSERT INTO HangThanhVien (MaHang, TenHang, DiemToiThieu, PhanTramGiam) VALUES
('THUONG',   N'Thường',      0, 0),
('BAC',      N'Bạc',        20, 2),
('VANG',     N'Vàng',       50, 5),
('KIMCUONG', N'Kim cương', 100, 8);

-- 4. Khách hàng ---------------------------------------------------------------
INSERT INTO KhachHang (MaKH, HoTen, SoDienThoai, NgayDangKy) VALUES
('KH01', N'Hoàng Thị Lan',    '0971000001', '2026-08-20'),
('KH02', N'Bùi Văn Minh',     '0971000002', '2026-08-25'),
('KH03', N'Ngô Thị Ngọc',     '0971000003', '2026-09-01'),
('KH04', N'Trịnh Quang Phúc', '0971000004', '2026-09-02'),
('KH05', N'Lý Thanh Quỳnh',   '0971000005', '2026-09-10'),
('KH06', N'Mai Đức Sơn',      '0971000006', '2026-09-15'),
('KH07', N'Phan Thị Thảo',    '0971000007', '2026-10-01'),
('KH08', N'Đỗ Minh Tuấn',     '0971000008', '2026-10-05'); -- chưa mua lần nào

-- 5. Danh mục -----------------------------------------------------------------
INSERT INTO DanhMuc (MaDM, TenDM, MoTa) VALUES
('DM01', N'Đồ uống',               N'Nước ngọt, nước suối, trà, cà phê, nước tăng lực'),
('DM02', N'Bánh kẹo - Snack',      N'Snack, bánh, kẹo'),
('DM03', N'Thực phẩm khô',         N'Mì, phở, cháo ăn liền'),
('DM04', N'Sữa và chế phẩm',       N'Sữa tươi, sữa chua, sữa đậu nành'),
('DM05', N'Hóa mỹ phẩm',           N'Chăm sóc cá nhân, vệ sinh'),
('DM06', N'Đồ ăn nhanh',           N'Hàng tươi trong ngày');

-- 6. Nhà cung cấp -------------------------------------------------------------
INSERT INTO NhaCungCap (MaNCC, TenNCC, SoDienThoai, Email, DiaChi) VALUES
('NCC01', N'Công ty CP Phân phối Đồ uống Sài Gòn', '02838000001', 'sales@douongsg.vn',  N'Quận 7, TP.HCM'),
('NCC02', N'Công ty TNHH Thực phẩm Phương Nam',    '02838000002', 'order@phuongnam.vn', N'Tân Phú, TP.HCM'),
('NCC03', N'Công ty CP Sữa và Dinh dưỡng Miền Nam','02838000003', 'kd@suamiennam.vn',   N'Thủ Đức, TP.HCM'),
('NCC04', N'Công ty TNHH Hóa mỹ phẩm Gia Định',    '02838000004', 'hmp@giadinh.vn',     N'Bình Thạnh, TP.HCM'),
('NCC05', N'Bếp trung tâm Hạnh Thông',             '02838000005', NULL,                 N'Gò Vấp, TP.HCM');

-- 7. Sản phẩm (SoLuongTon mặc định 0, sẽ tăng khi nhập hàng) ------------------
INSERT INTO SanPham (MaSP, MaVach, TenSP, MaDM, DonViTinh, GiaBan, TonToiThieu) VALUES
('SP01', '8930000000011', N'Nước ngọt Coca-Cola lon 320ml',    'DM01', N'Lon',   10000, 10),
('SP02', '8930000000028', N'Nước suối Aquafina 500ml',         'DM01', N'Chai',   6000, 20),
('SP03', '8930000000035', N'Trà xanh Không Độ 455ml',          'DM01', N'Chai',  10000, 10),
('SP04', '8930000000042', N'Cà phê sữa đá lon 235ml',          'DM01', N'Lon',   15000, 10),
('SP05', '8930000000059', N'Snack khoai tây Lay''s 52g',       'DM02', N'Gói',   12000, 10),
('SP06', '8930000000066', N'Bánh Chocopie hộp 2 cái',          'DM02', N'Hộp',    9000, 10),
('SP07', '8930000000073', N'Kẹo cao su Doublemint',            'DM02', N'Thanh',  5000, 10),
('SP08', '8930000000080', N'Mì Hảo Hảo tôm chua cay 75g',      'DM03', N'Gói',    4500, 30),
('SP09', '8930000000097', N'Mì ly lẩu Thái 65g',               'DM03', N'Ly',     9000, 15),
('SP10', '8930000000103', N'Phở bò ăn liền 65g',               'DM03', N'Gói',    8000, 15),
('SP11', '8930000000110', N'Sữa tươi Vinamilk có đường 180ml', 'DM04', N'Hộp',    8000, 20),
('SP12', '8930000000127', N'Sữa chua uống Probi (lốc 5)',      'DM04', N'Lốc',   26000,  5),
('SP13', '8930000000134', N'Sữa đậu nành Fami 200ml',          'DM04', N'Hộp',    6000, 20),
('SP14', '8930000000141', N'Khăn giấy ướt 10 tờ',              'DM05', N'Gói',   10000,  5),
('SP15', '8930000000158', N'Kem đánh răng P/S 100g',           'DM05', N'Tuýp',  25000,  5),
('SP16', '8930000000165', N'Dầu gội Clear 170ml',              'DM05', N'Chai',  69000,  3),
('SP17', '2000000000017', N'Bánh mì xúc xích',                 'DM06', N'Cái',   15000,  5),
('SP18', '2000000000024', N'Cơm nắm cá ngừ',                   'DM06', N'Cái',   18000,  5),
('SP19', '2000000000031', N'Xúc xích nướng',                   'DM06', N'Cây',   12000,  5),
('SP20', '8930000000172', N'Nước tăng lực Sting 330ml',        'DM01', N'Chai',  12000, 10);
GO

-- 8. Phiếu nhập (MaPN tự tăng 1..6) -------------------------------------------
INSERT INTO PhieuNhap (NgayNhap, MaNCC, MaNV, GhiChu) VALUES
('2026-09-01 08:00:00', 'NCC01', 'NV04', N'Nhập đồ uống đầu tháng 9'),
('2026-09-01 10:00:00', 'NCC02', 'NV04', N'Nhập bánh kẹo, thực phẩm khô'),
('2026-09-02 09:00:00', 'NCC03', 'NV04', N'Nhập sữa'),
('2026-09-03 09:30:00', 'NCC04', 'NV04', N'Nhập hóa mỹ phẩm'),
('2026-10-01 07:00:00', 'NCC05', 'NV04', N'Nhập đồ ăn nhanh'),
('2026-10-02 08:00:00', 'NCC01', 'NV01', N'Bổ sung đồ uống, giá nhập tăng');

INSERT INTO ChiTietPhieuNhap (MaPN, MaSP, SoLuong, DonGiaNhap, HanSuDung) VALUES
(1, 'SP01', 120,  7200, '2027-06-30'),
(1, 'SP02', 200,  3800, '2027-09-30'),
(1, 'SP03', 100,  7000, '2027-03-31'),
(1, 'SP04',  60, 11000, '2027-01-31'),
(1, 'SP20', 100,  8500, '2027-05-31'),
(2, 'SP05',  60,  8500, '2027-02-28'),
(2, 'SP06',  80,  6200, '2027-01-31'),
(2, 'SP07',  50,  3200, '2027-12-31'),
(2, 'SP08', 300,  3300, '2027-03-31'),
(2, 'SP09', 100,  6300, '2027-03-31'),
(2, 'SP10',  80,  5600, '2027-03-31'),
(3, 'SP11', 200,  6000, '2026-12-31'),
(3, 'SP12',  40, 20000, '2026-10-30'),
(3, 'SP13', 150,  4200, '2026-12-31'),
(4, 'SP14',  30,  6500, '2028-12-31'),
(4, 'SP15',  20, 18000, '2028-06-30'),
(4, 'SP16',   4, 52000, '2028-06-30'),
(5, 'SP17',  30, 10000, '2026-10-09'),
(5, 'SP18',  10, 12500, '2026-10-09'),
(5, 'SP19',  40,  8000, '2026-10-15'),
(6, 'SP01',  48,  7300, '2027-08-31'),
(6, 'SP20',  48,  8600, '2027-07-31');
GO

-- 9. Hóa đơn (MaHD tự tăng 1..20), tạo ở trạng thái "Đang lập" ----------------
--    PhanTramGiam = mức giảm theo hạng của khách TẠI THỜI ĐIỂM mua
INSERT INTO HoaDon (NgayLap, MaNV, MaKH, PhanTramGiam, PhuongThucTT) VALUES
('2026-09-05 07:15:00', 'NV02', 'KH01', 0, N'Tiền mặt'),      -- 1
('2026-09-05 12:10:00', 'NV02', NULL,   0, N'Tiền mặt'),      -- 2
('2026-09-08 18:40:00', 'NV03', 'KH02', 0, N'Chuyển khoản'),  -- 3
('2026-09-10 21:05:00', 'NV03', 'KH03', 0, N'Ví điện tử'),    -- 4
('2026-09-12 07:30:00', 'NV05', 'KH01', 0, N'Tiền mặt'),      -- 5
('2026-09-15 12:20:00', 'NV02', NULL,   0, N'Tiền mặt'),      -- 6
('2026-09-18 19:00:00', 'NV05', 'KH04', 0, N'Thẻ'),           -- 7
('2026-09-22 22:15:00', 'NV03', 'KH02', 0, N'Chuyển khoản'),  -- 8
('2026-09-25 18:30:00', 'NV06', NULL,   0, N'Tiền mặt'),      -- 9  (NV06 lúc đó còn làm)
('2026-09-28 12:05:00', 'NV02', 'KH05', 0, N'Ví điện tử'),    -- 10 (sẽ bị hủy)
('2026-10-01 07:10:00', 'NV05', 'KH01', 0, N'Tiền mặt'),      -- 11
('2026-10-01 12:30:00', 'NV02', 'KH03', 0, N'Chuyển khoản'),  -- 12
('2026-10-02 18:45:00', 'NV03', 'KH02', 2, N'Chuyển khoản'),  -- 13 (KH02 đã lên hạng Bạc)
('2026-10-03 19:20:00', 'NV05', NULL,   0, N'Tiền mặt'),      -- 14
('2026-10-04 21:30:00', 'NV03', 'KH06', 0, N'Ví điện tử'),    -- 15
('2026-10-05 07:25:00', 'NV02', 'KH01', 0, N'Thẻ'),           -- 16
('2026-10-06 12:15:00', 'NV05', 'KH04', 0, N'Tiền mặt'),      -- 17
('2026-10-07 18:50:00', 'NV03', NULL,   0, N'Ví điện tử'),    -- 18
('2026-10-07 22:40:00', 'NV02', 'KH07', 0, N'Chuyển khoản'),  -- 19
('2026-10-08 07:05:00', 'NV05', 'KH02', 2, N'Tiền mặt');      -- 20
GO

-- 10. Chi tiết hóa đơn: đơn giá bán lấy theo giá bán hiện tại của sản phẩm ----
--     (trigger tự kiểm tra và trừ tồn kho)
INSERT INTO ChiTietHoaDon (MaHD, MaSP, SoLuong, DonGiaBan)
SELECT v.MaHD, v.MaSP, v.SoLuong, sp.GiaBan
FROM (VALUES
    ( 1, 'SP04',  2), ( 1, 'SP06', 1),
    ( 2, 'SP08',  5), ( 2, 'SP02', 2),
    ( 3, 'SP01',  6), ( 3, 'SP05', 3), ( 3, 'SP12', 1),
    ( 4, 'SP09',  2), ( 4, 'SP20', 2),
    ( 5, 'SP11',  6), ( 5, 'SP13', 4),
    ( 6, 'SP03',  2), ( 6, 'SP08', 3),
    ( 7, 'SP15',  1), ( 7, 'SP16', 1), ( 7, 'SP14', 1),
    ( 8, 'SP01', 12), ( 8, 'SP05', 4),
    ( 9, 'SP20',  3),
    (10, 'SP09',  3), (10, 'SP13', 2),
    (11, 'SP17',  2), (11, 'SP11', 2),
    (12, 'SP18',  3), (12, 'SP02', 3),
    (13, 'SP01', 10), (13, 'SP12', 2), (13, 'SP19', 4),
    (14, 'SP18',  2), (14, 'SP04', 1),
    (15, 'SP16',  1), (15, 'SP15', 1),
    (16, 'SP04',  3), (16, 'SP06', 2),
    (17, 'SP08', 10), (17, 'SP18', 2), (17, 'SP03', 2),
    (18, 'SP19',  3), (18, 'SP20', 2), (18, 'SP05', 1),
    (19, 'SP12',  1), (19, 'SP11', 4),
    (20, 'SP17',  3), (20, 'SP13', 3)
) AS v (MaHD, MaSP, SoLuong)
JOIN SanPham sp ON sp.MaSP = v.MaSP;
GO

-- 11. Chốt trạng thái hóa đơn -------------------------------------------------
UPDATE HoaDon SET TrangThai = N'Đã thanh toán' WHERE MaHD <> 10;

-- Hóa đơn 10 bị hủy -> trigger hoàn lại tồn kho SP09 (+3), SP13 (+2)
UPDATE HoaDon SET TrangThai = N'Đã hủy', GhiChu = N'Khách đổi ý, không lấy hàng' WHERE MaHD = 10;
GO

PRINT N'>> Đã nạp dữ liệu mẫu.';
SELECT 'ChucVu' AS Bang, COUNT(*) AS SoDong FROM ChucVu UNION ALL
SELECT 'NhanVien', COUNT(*) FROM NhanVien UNION ALL
SELECT 'HangThanhVien', COUNT(*) FROM HangThanhVien UNION ALL
SELECT 'KhachHang', COUNT(*) FROM KhachHang UNION ALL
SELECT 'DanhMuc', COUNT(*) FROM DanhMuc UNION ALL
SELECT 'NhaCungCap', COUNT(*) FROM NhaCungCap UNION ALL
SELECT 'SanPham', COUNT(*) FROM SanPham UNION ALL
SELECT 'PhieuNhap', COUNT(*) FROM PhieuNhap UNION ALL
SELECT 'ChiTietPhieuNhap', COUNT(*) FROM ChiTietPhieuNhap UNION ALL
SELECT 'HoaDon', COUNT(*) FROM HoaDon UNION ALL
SELECT 'ChiTietHoaDon', COUNT(*) FROM ChiTietHoaDon;
GO
