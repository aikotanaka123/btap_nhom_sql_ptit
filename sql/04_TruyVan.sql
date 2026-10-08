/* ==========================================================================
   FILE 04 : Truy vấn CSDL (25 câu, từ cơ bản đến nâng cao)
   Quy ước: "doanh thu" chỉ tính hóa đơn có TrangThai = N'Đã thanh toán'
   ========================================================================== */
USE QLCuaHangTienLoi;
GO

/* ==========================================================================
   I. TRUY VẤN CƠ BẢN (SELECT, WHERE, ORDER BY, LIKE, BETWEEN)
   ========================================================================== */

-- Câu 1. Danh sách sản phẩm đang kinh doanh, sắp xếp theo giá bán giảm dần
SELECT MaSP, TenSP, DonViTinh, GiaBan, SoLuongTon
FROM SanPham
WHERE DangKinhDoanh = 1
ORDER BY GiaBan DESC;

-- Câu 2. Các loại đồ uống có giá bán từ 8.000đ đến 12.000đ
SELECT sp.MaSP, sp.TenSP, sp.GiaBan
FROM SanPham sp
JOIN DanhMuc dm ON dm.MaDM = sp.MaDM
WHERE dm.TenDM = N'Đồ uống'
  AND sp.GiaBan BETWEEN 8000 AND 12000;

-- Câu 3. Nhân viên đang làm việc có họ "Nguyễn" hoặc "Trần"
SELECT MaNV, HoTen, SoDienThoai
FROM NhanVien
WHERE DangLamViec = 1
  AND (HoTen LIKE N'Nguyễn %' OR HoTen LIKE N'Trần %');

/* ==========================================================================
   II. TRUY VẤN KẾT NỐI (INNER JOIN, LEFT JOIN)
   ========================================================================== */

-- Câu 4. Danh sách nhân viên kèm chức vụ và lương cơ bản
SELECT nv.MaNV, nv.HoTen, cv.TenCV, cv.LuongCoBan,
       CASE nv.DangLamViec WHEN 1 THEN N'Đang làm' ELSE N'Đã nghỉ' END AS TinhTrang
FROM NhanVien nv
JOIN ChucVu cv ON cv.MaCV = nv.MaCV
ORDER BY cv.LuongCoBan DESC, nv.HoTen;

-- Câu 5. In chi tiết hóa đơn số 13 (như tờ hóa đơn in ra cho khách)
SELECT ct.MaSP, sp.TenSP, ct.SoLuong, ct.DonGiaBan,
       ct.SoLuong * ct.DonGiaBan AS ThanhTien
FROM ChiTietHoaDon ct
JOIN SanPham sp ON sp.MaSP = ct.MaSP
WHERE ct.MaHD = 13;

SELECT MaHD, TienHang, PhanTramGiam, TienGiam, ThanhTien
FROM v_HoaDonTongTien
WHERE MaHD = 13;

-- Câu 6. Tất cả hóa đơn kèm tên nhân viên lập và tên khách (khách lẻ nếu không có)
SELECT v.MaHD, v.NgayLap, nv.HoTen AS NhanVien,
       ISNULL(kh.HoTen, N'Khách lẻ') AS KhachHang,
       v.PhuongThucTT, v.TrangThai, v.ThanhTien
FROM v_HoaDonTongTien v
JOIN NhanVien nv ON nv.MaNV = v.MaNV
LEFT JOIN KhachHang kh ON kh.MaKH = v.MaKH
ORDER BY v.NgayLap;

-- Câu 7. Danh sách phiếu nhập kèm nhà cung cấp và tổng tiền nhập
SELECT pn.MaPN, pn.NgayNhap, ncc.TenNCC, nv.HoTen AS NguoiNhap,
       SUM(ct.SoLuong)                 AS TongSoLuong,
       SUM(ct.SoLuong * ct.DonGiaNhap) AS TongTienNhap
FROM PhieuNhap pn
JOIN NhaCungCap ncc ON ncc.MaNCC = pn.MaNCC
JOIN NhanVien nv    ON nv.MaNV = pn.MaNV
JOIN ChiTietPhieuNhap ct ON ct.MaPN = pn.MaPN
GROUP BY pn.MaPN, pn.NgayNhap, ncc.TenNCC, nv.HoTen
ORDER BY pn.NgayNhap;

/* ==========================================================================
   III. TRUY VẤN GOM NHÓM (GROUP BY, HAVING, hàm tổng hợp)
   ========================================================================== */

-- Câu 8. Số sản phẩm và giá bán trung bình theo từng danh mục
SELECT dm.TenDM,
       COUNT(sp.MaSP)                           AS SoSanPham,
       CAST(AVG(sp.GiaBan) AS DECIMAL(12, 0))   AS GiaBanTrungBinh,
       SUM(sp.SoLuongTon)                       AS TongTonKho
FROM DanhMuc dm
LEFT JOIN SanPham sp ON sp.MaDM = dm.MaDM
GROUP BY dm.TenDM
ORDER BY SoSanPham DESC;

-- Câu 9. Doanh thu theo tháng
SELECT YEAR(NgayLap) AS Nam, MONTH(NgayLap) AS Thang,
       COUNT(*) AS SoHoaDon, SUM(ThanhTien) AS DoanhThu
FROM v_HoaDonTongTien
WHERE TrangThai = N'Đã thanh toán'
GROUP BY YEAR(NgayLap), MONTH(NgayLap)
ORDER BY Nam, Thang;

-- Câu 10. Doanh thu của từng nhân viên trong tháng 10/2026
SELECT nv.MaNV, nv.HoTen,
       COUNT(v.MaHD)  AS SoHoaDon,
       SUM(v.ThanhTien) AS DoanhThu
FROM v_HoaDonTongTien v
JOIN NhanVien nv ON nv.MaNV = v.MaNV
WHERE v.TrangThai = N'Đã thanh toán'
  AND v.NgayLap >= '2026-10-01' AND v.NgayLap < '2026-11-01'
GROUP BY nv.MaNV, nv.HoTen
ORDER BY DoanhThu DESC;

-- Câu 11. Top 5 sản phẩm bán chạy nhất (theo số lượng)
SELECT TOP 5 sp.MaSP, sp.TenSP,
       SUM(ct.SoLuong)                AS SoLuongBan,
       SUM(ct.SoLuong * ct.DonGiaBan) AS DoanhSo
FROM ChiTietHoaDon ct
JOIN HoaDon  hd ON hd.MaHD = ct.MaHD
JOIN SanPham sp ON sp.MaSP = ct.MaSP
WHERE hd.TrangThai = N'Đã thanh toán'
GROUP BY sp.MaSP, sp.TenSP
ORDER BY SoLuongBan DESC;

-- Câu 12. Doanh số theo danh mục, chỉ lấy danh mục có doanh số trên 200.000đ
SELECT TenDM, SUM(ThanhTienDong) AS DoanhSo
FROM v_ChiTietBanHang
WHERE TrangThai = N'Đã thanh toán'
GROUP BY TenDM
HAVING SUM(ThanhTienDong) > 200000
ORDER BY DoanhSo DESC;

-- Câu 13. Khách hàng mua từ 3 hóa đơn trở lên
SELECT kh.MaKH, kh.HoTen, COUNT(*) AS SoLanMua, SUM(v.ThanhTien) AS TongChiTieu
FROM KhachHang kh
JOIN v_HoaDonTongTien v ON v.MaKH = kh.MaKH
WHERE v.TrangThai = N'Đã thanh toán'
GROUP BY kh.MaKH, kh.HoTen
HAVING COUNT(*) >= 3
ORDER BY TongChiTieu DESC;

-- Câu 14. Tỷ lệ sử dụng các phương thức thanh toán
SELECT PhuongThucTT,
       COUNT(*) AS SoHoaDon,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5, 1)) AS TyLePhanTram
FROM HoaDon
WHERE TrangThai = N'Đã thanh toán'
GROUP BY PhuongThucTT
ORDER BY SoHoaDon DESC;

/* ==========================================================================
   IV. TRUY VẤN LỒNG (subquery, EXISTS / NOT EXISTS, IN, tương quan)
   ========================================================================== */

-- Câu 15. Sản phẩm CHƯA từng được bán
SELECT sp.MaSP, sp.TenSP, sp.SoLuongTon
FROM SanPham sp
WHERE NOT EXISTS (SELECT 1
                  FROM ChiTietHoaDon ct
                  JOIN HoaDon hd ON hd.MaHD = ct.MaHD
                  WHERE ct.MaSP = sp.MaSP
                    AND hd.TrangThai = N'Đã thanh toán');

-- Câu 16. Khách hàng đã đăng ký nhưng chưa mua hàng lần nào
SELECT MaKH, HoTen, SoDienThoai, NgayDangKy
FROM KhachHang
WHERE MaKH NOT IN (SELECT MaKH FROM HoaDon
                   WHERE MaKH IS NOT NULL AND TrangThai = N'Đã thanh toán');

-- Câu 17. Sản phẩm có giá bán cao hơn giá trung bình của danh mục chứa nó (lồng tương quan)
SELECT sp.MaSP, sp.TenSP, sp.MaDM, sp.GiaBan
FROM SanPham sp
WHERE sp.GiaBan > (SELECT AVG(sp2.GiaBan)
                   FROM SanPham sp2
                   WHERE sp2.MaDM = sp.MaDM)
ORDER BY sp.MaDM;

-- Câu 18. Hóa đơn có giá trị lớn nhất (lấy cả trường hợp bằng nhau)
SELECT TOP 1 WITH TIES MaHD, NgayLap, ThanhTien
FROM v_HoaDonTongTien
WHERE TrangThai = N'Đã thanh toán'
ORDER BY ThanhTien DESC;

-- Câu 19. Nhân viên có doanh thu tháng 10/2026 cao hơn doanh thu trung bình của các nhân viên
WITH DoanhThuNV AS (
    SELECT MaNV, SUM(ThanhTien) AS DoanhThu
    FROM v_HoaDonTongTien
    WHERE TrangThai = N'Đã thanh toán'
      AND NgayLap >= '2026-10-01' AND NgayLap < '2026-11-01'
    GROUP BY MaNV
)
SELECT nv.HoTen, d.DoanhThu
FROM DoanhThuNV d
JOIN NhanVien nv ON nv.MaNV = d.MaNV
WHERE d.DoanhThu > (SELECT AVG(DoanhThu) FROM DoanhThuNV);

/* ==========================================================================
   V. TRUY VẤN NÂNG CAO (CTE, hàm cửa sổ, PIVOT)
   ========================================================================== */

-- Câu 20. Lợi nhuận gộp ước tính theo sản phẩm (giá vốn bình quân gia quyền)
WITH BanHang AS (
    SELECT ct.MaSP,
           SUM(ct.SoLuong)                AS SoLuongBan,
           SUM(ct.SoLuong * ct.DonGiaBan) AS DoanhSo
    FROM ChiTietHoaDon ct
    JOIN HoaDon hd ON hd.MaHD = ct.MaHD
    WHERE hd.TrangThai = N'Đã thanh toán'
    GROUP BY ct.MaSP
)
SELECT sp.MaSP, sp.TenSP, b.SoLuongBan, b.DoanhSo,
       CAST(b.SoLuongBan * dbo.fn_GiaVonBinhQuan(sp.MaSP) AS DECIMAL(14, 0)) AS GiaVon,
       CAST(b.DoanhSo - b.SoLuongBan * dbo.fn_GiaVonBinhQuan(sp.MaSP) AS DECIMAL(14, 0)) AS LoiNhuanGop
FROM BanHang b
JOIN SanPham sp ON sp.MaSP = b.MaSP
ORDER BY LoiNhuanGop DESC;

-- Câu 21. Xếp hạng nhân viên theo tổng doanh thu (RANK)
SELECT nv.HoTen,
       SUM(v.ThanhTien) AS DoanhThu,
       RANK() OVER (ORDER BY SUM(v.ThanhTien) DESC) AS XepHang
FROM v_HoaDonTongTien v
JOIN NhanVien nv ON nv.MaNV = v.MaNV
WHERE v.TrangThai = N'Đã thanh toán'
GROUP BY nv.HoTen;

-- Câu 22. Doanh thu theo ngày và doanh thu lũy kế
SELECT Ngay, SoHoaDon, DoanhThu,
       SUM(DoanhThu) OVER (ORDER BY Ngay ROWS UNBOUNDED PRECEDING) AS DoanhThuLuyKe
FROM dbo.fn_DoanhThuTheoNgay('2026-09-01', '2026-10-31')
ORDER BY Ngay;

-- Câu 23. Khung giờ bán hàng đông nhất
SELECT CASE
           WHEN DATEPART(HOUR, NgayLap) BETWEEN 6  AND 10 THEN N'1. Sáng (6h-11h)'
           WHEN DATEPART(HOUR, NgayLap) BETWEEN 11 AND 13 THEN N'2. Trưa (11h-14h)'
           WHEN DATEPART(HOUR, NgayLap) BETWEEN 14 AND 17 THEN N'3. Chiều (14h-18h)'
           WHEN DATEPART(HOUR, NgayLap) BETWEEN 18 AND 21 THEN N'4. Tối (18h-22h)'
           ELSE N'5. Đêm (22h-6h)'
       END AS KhungGio,
       COUNT(*) AS SoHoaDon,
       SUM(ThanhTien) AS DoanhThu
FROM v_HoaDonTongTien
WHERE TrangThai = N'Đã thanh toán'
GROUP BY CASE
           WHEN DATEPART(HOUR, NgayLap) BETWEEN 6  AND 10 THEN N'1. Sáng (6h-11h)'
           WHEN DATEPART(HOUR, NgayLap) BETWEEN 11 AND 13 THEN N'2. Trưa (11h-14h)'
           WHEN DATEPART(HOUR, NgayLap) BETWEEN 14 AND 17 THEN N'3. Chiều (14h-18h)'
           WHEN DATEPART(HOUR, NgayLap) BETWEEN 18 AND 21 THEN N'4. Tối (18h-22h)'
           ELSE N'5. Đêm (22h-6h)'
         END
ORDER BY KhungGio;

-- Câu 24. So sánh số lượng bán từng danh mục giữa tháng 9 và tháng 10 (PIVOT)
SELECT TenDM,
       ISNULL([9], 0)  AS Thang9,
       ISNULL([10], 0) AS Thang10
FROM (SELECT TenDM, MONTH(NgayLap) AS Thang, SoLuong
      FROM v_ChiTietBanHang
      WHERE TrangThai = N'Đã thanh toán') AS src
PIVOT (SUM(SoLuong) FOR Thang IN ([9], [10])) AS pv
ORDER BY TenDM;

-- Câu 25. Sản phẩm bán chạy nhất của TỪNG danh mục (ROW_NUMBER theo nhóm)
WITH XepHang AS (
    SELECT TenDM, TenSP, SUM(SoLuong) AS SoLuongBan,
           ROW_NUMBER() OVER (PARTITION BY TenDM ORDER BY SUM(SoLuong) DESC) AS STT
    FROM v_ChiTietBanHang
    WHERE TrangThai = N'Đã thanh toán'
    GROUP BY TenDM, TenSP
)
SELECT TenDM, TenSP, SoLuongBan
FROM XepHang
WHERE STT = 1;

/* ==========================================================================
   VI. SỬ DỤNG VIEW / FUNCTION / PROCEDURE ĐÃ TẠO
   ========================================================================== */

-- Khách hàng thành viên: điểm tích lũy và hạng hiện tại
SELECT * FROM v_KhachHangThanhVien ORDER BY DiemTichLuy DESC;

-- Sản phẩm sắp hết hàng cần nhập thêm
SELECT * FROM v_SanPhamCanNhap;

-- Tổng tiền một hóa đơn bằng hàm vô hướng
SELECT dbo.fn_TongTienHoaDon(8) AS TongTienHoaDon8;

-- Hạng tương ứng với 55 điểm
SELECT dbo.fn_XepHangThanhVien(55) AS Hang;

-- Báo cáo doanh thu tháng 10/2026 có dòng tổng cộng
EXEC sp_BaoCaoDoanhThu @TuNgay = '2026-10-01', @DenNgay = '2026-10-31';

/* ==========================================================================
   VII. CẬP NHẬT DỮ LIỆU (INSERT / UPDATE / DELETE)
   Bọc trong giao dịch và ROLLBACK để chạy thử không làm thay đổi dữ liệu mẫu.
   Muốn lưu thật thì đổi ROLLBACK thành COMMIT.
   ========================================================================== */
BEGIN TRANSACTION;

    -- Thêm khách hàng mới
    INSERT INTO KhachHang (MaKH, HoTen, SoDienThoai) VALUES ('KH09', N'Châu Gia Vy', '0971000009');

    -- Tăng giá 5% cho toàn bộ đồ uống (làm tròn đến 500đ)
    UPDATE sp
    SET    GiaBan = CEILING(GiaBan * 1.05 / 500) * 500
    FROM   SanPham sp
    JOIN   DanhMuc dm ON dm.MaDM = sp.MaDM
    WHERE  dm.TenDM = N'Đồ uống';

    -- Ngừng kinh doanh sản phẩm không bán được
    UPDATE SanPham SET DangKinhDoanh = 0 WHERE MaSP = 'SP07';

    -- Xóa khách hàng chưa từng mua hàng (không vướng khóa ngoại)
    DELETE FROM KhachHang
    WHERE MaKH NOT IN (SELECT MaKH FROM HoaDon WHERE MaKH IS NOT NULL);

    SELECT MaSP, TenSP, GiaBan, DangKinhDoanh FROM SanPham WHERE MaDM = 'DM01' OR MaSP = 'SP07';

ROLLBACK TRANSACTION;
GO
