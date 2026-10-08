/* ==========================================================================
   FILE 02 : View, Function, Trigger, Stored Procedure
   Yêu cầu : SQL Server 2016 SP1 trở lên (dùng CREATE OR ALTER, THROW)
   ========================================================================== */
USE QLCuaHangTienLoi;
GO

/* ==========================================================================
   PHẦN A. FUNCTION
   ========================================================================== */

-- A1. Tổng tiền phải trả của 1 hóa đơn (đã trừ giảm giá)
CREATE OR ALTER FUNCTION fn_TongTienHoaDon (@MaHD INT)
RETURNS DECIMAL(14, 0)
AS
BEGIN
    DECLARE @TienHang DECIMAL(14, 0), @PhanTram DECIMAL(4, 1);

    SELECT @TienHang = ISNULL(SUM(SoLuong * DonGiaBan), 0)
    FROM ChiTietHoaDon
    WHERE MaHD = @MaHD;

    SELECT @PhanTram = PhanTramGiam FROM HoaDon WHERE MaHD = @MaHD;

    RETURN @TienHang - ROUND(@TienHang * ISNULL(@PhanTram, 0) / 100, 0);
END
GO

-- A2. Giá vốn bình quân gia quyền của 1 sản phẩm (dựa trên tất cả phiếu nhập)
CREATE OR ALTER FUNCTION fn_GiaVonBinhQuan (@MaSP VARCHAR(10))
RETURNS DECIMAL(14, 2)
AS
BEGIN
    DECLARE @GiaVon DECIMAL(14, 2);

    SELECT @GiaVon = CAST(SUM(SoLuong * DonGiaNhap) AS DECIMAL(18, 2)) / NULLIF(SUM(SoLuong), 0)
    FROM ChiTietPhieuNhap
    WHERE MaSP = @MaSP;

    RETURN ISNULL(@GiaVon, 0);
END
GO

-- A3. Hạng thành viên tương ứng với số điểm
CREATE OR ALTER FUNCTION fn_XepHangThanhVien (@Diem INT)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN (SELECT TOP 1 MaHang
            FROM HangThanhVien
            WHERE DiemToiThieu <= @Diem
            ORDER BY DiemToiThieu DESC);
END
GO

/* ==========================================================================
   PHẦN B. VIEW
   ========================================================================== */

-- B1. Hóa đơn kèm tiền hàng, tiền giảm, thành tiền
CREATE OR ALTER VIEW v_HoaDonTongTien
AS
SELECT  hd.MaHD,
        hd.NgayLap,
        hd.MaNV,
        hd.MaKH,
        hd.PhuongThucTT,
        hd.TrangThai,
        hd.PhanTramGiam,
        CAST(ISNULL(ct.TienHang, 0) AS DECIMAL(14, 0))                                    AS TienHang,
        CAST(ROUND(ISNULL(ct.TienHang, 0) * hd.PhanTramGiam / 100, 0) AS DECIMAL(14, 0))  AS TienGiam,
        CAST(ISNULL(ct.TienHang, 0)
             - ROUND(ISNULL(ct.TienHang, 0) * hd.PhanTramGiam / 100, 0) AS DECIMAL(14, 0)) AS ThanhTien
FROM HoaDon hd
LEFT JOIN (SELECT MaHD, SUM(SoLuong * DonGiaBan) AS TienHang
           FROM ChiTietHoaDon
           GROUP BY MaHD) ct ON ct.MaHD = hd.MaHD;
GO

-- B2. Khách hàng kèm tổng chi tiêu, điểm tích lũy và hạng HIỆN TẠI
--     (điểm & hạng được TÍNH, không lưu -> luôn đúng, không vi phạm 3NF)
CREATE OR ALTER VIEW v_KhachHangThanhVien
AS
SELECT  kh.MaKH,
        kh.HoTen,
        kh.SoDienThoai,
        kh.NgayDangKy,
        CAST(ISNULL(cs.TongChiTieu, 0) AS DECIMAL(14, 0))       AS TongChiTieu,
        CAST(FLOOR(ISNULL(cs.TongChiTieu, 0) / 10000) AS INT)   AS DiemTichLuy,
        h.MaHang,
        h.TenHang,
        h.PhanTramGiam
FROM KhachHang kh
OUTER APPLY (SELECT SUM(v.ThanhTien) AS TongChiTieu
             FROM v_HoaDonTongTien v
             WHERE v.MaKH = kh.MaKH
               AND v.TrangThai = N'Đã thanh toán') cs
OUTER APPLY (SELECT TOP 1 MaHang, TenHang, PhanTramGiam
             FROM HangThanhVien
             WHERE DiemToiThieu <= FLOOR(ISNULL(cs.TongChiTieu, 0) / 10000)
             ORDER BY DiemToiThieu DESC) h;
GO

-- B3. Sản phẩm đang kinh doanh có tồn kho <= mức tối thiểu -> cần nhập thêm
CREATE OR ALTER VIEW v_SanPhamCanNhap
AS
SELECT  sp.MaSP,
        sp.TenSP,
        dm.TenDM,
        sp.SoLuongTon,
        sp.TonToiThieu,
        sp.TonToiThieu * 3 - sp.SoLuongTon AS SoLuongDeXuatNhap
FROM SanPham sp
JOIN DanhMuc dm ON dm.MaDM = sp.MaDM
WHERE sp.DangKinhDoanh = 1
  AND sp.SoLuongTon <= sp.TonToiThieu;
GO

-- B4. Chi tiết bán hàng đầy đủ (dùng cho báo cáo)
CREATE OR ALTER VIEW v_ChiTietBanHang
AS
SELECT  hd.MaHD,
        hd.NgayLap,
        hd.TrangThai,
        nv.MaNV,
        nv.HoTen                                 AS TenNhanVien,
        ISNULL(kh.HoTen, N'Khách lẻ')            AS TenKhachHang,
        sp.MaSP,
        sp.TenSP,
        dm.TenDM,
        ct.SoLuong,
        ct.DonGiaBan,
        ct.SoLuong * ct.DonGiaBan                AS ThanhTienDong
FROM ChiTietHoaDon ct
JOIN HoaDon   hd ON hd.MaHD = ct.MaHD
JOIN NhanVien nv ON nv.MaNV = hd.MaNV
LEFT JOIN KhachHang kh ON kh.MaKH = hd.MaKH
JOIN SanPham  sp ON sp.MaSP = ct.MaSP
JOIN DanhMuc  dm ON dm.MaDM = sp.MaDM;
GO

-- A4. (đặt sau view vì dùng view) Doanh thu theo từng ngày trong khoảng thời gian
CREATE OR ALTER FUNCTION fn_DoanhThuTheoNgay (@TuNgay DATE, @DenNgay DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT  CAST(NgayLap AS DATE) AS Ngay,
            COUNT(*)              AS SoHoaDon,
            SUM(ThanhTien)        AS DoanhThu
    FROM v_HoaDonTongTien
    WHERE TrangThai = N'Đã thanh toán'
      AND CAST(NgayLap AS DATE) BETWEEN @TuNgay AND @DenNgay
    GROUP BY CAST(NgayLap AS DATE)
);
GO

/* ==========================================================================
   PHẦN C. TRIGGER (tự động cập nhật tồn kho & bảo vệ nghiệp vụ)
   Lưu ý: trong trigger, XACT_ABORT mặc định ON nên THROW sẽ hủy (rollback)
          toàn bộ giao dịch đang thực hiện.
   ========================================================================== */

-- C1. Nhập hàng: thêm / sửa / xóa chi tiết phiếu nhập -> cộng / trừ tồn kho
CREATE OR ALTER TRIGGER trg_ChiTietPhieuNhap_CapNhatTon
ON ChiTietPhieuNhap
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ThayDoi TABLE (MaSP VARCHAR(10) PRIMARY KEY, ChenhLech INT NOT NULL);

    INSERT INTO @ThayDoi (MaSP, ChenhLech)
    SELECT MaSP, SUM(SoLuong)
    FROM (SELECT MaSP, SoLuong FROM inserted
          UNION ALL
          SELECT MaSP, -SoLuong FROM deleted) AS t
    GROUP BY MaSP;

    IF EXISTS (SELECT 1
               FROM SanPham sp
               JOIN @ThayDoi t ON t.MaSP = sp.MaSP
               WHERE sp.SoLuongTon + t.ChenhLech < 0)
    BEGIN
        THROW 50001, N'Không thể sửa/xóa phiếu nhập: số hàng này đã được bán, tồn kho sẽ bị âm.', 1;
    END

    UPDATE sp
    SET    sp.SoLuongTon = sp.SoLuongTon + t.ChenhLech
    FROM   SanPham sp
    JOIN   @ThayDoi t ON t.MaSP = sp.MaSP;
END
GO

-- C2. Bán hàng: thêm / sửa / xóa chi tiết hóa đơn -> kiểm tra & trừ tồn kho
CREATE OR ALTER TRIGGER trg_ChiTietHoaDon_CapNhatTon
ON ChiTietHoaDon
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ được sửa chi tiết khi hóa đơn còn ở trạng thái "Đang lập"
    IF EXISTS (SELECT 1
               FROM HoaDon hd
               WHERE hd.TrangThai <> N'Đang lập'
                 AND hd.MaHD IN (SELECT MaHD FROM inserted UNION SELECT MaHD FROM deleted))
    BEGIN
        THROW 50002, N'Chỉ được thay đổi chi tiết của hóa đơn đang lập.', 1;
    END

    -- Không bán sản phẩm đã ngừng kinh doanh
    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN SanPham sp ON sp.MaSP = i.MaSP
               WHERE sp.DangKinhDoanh = 0)
    BEGIN
        THROW 50003, N'Sản phẩm đã ngừng kinh doanh, không thể bán.', 1;
    END

    DECLARE @ThayDoi TABLE (MaSP VARCHAR(10) PRIMARY KEY, SoLuongBan INT NOT NULL);

    INSERT INTO @ThayDoi (MaSP, SoLuongBan)
    SELECT MaSP, SUM(SoLuong)
    FROM (SELECT MaSP, SoLuong FROM inserted
          UNION ALL
          SELECT MaSP, -SoLuong FROM deleted) AS t
    GROUP BY MaSP;

    -- Kiểm tra đủ hàng
    IF EXISTS (SELECT 1
               FROM SanPham sp
               JOIN @ThayDoi t ON t.MaSP = sp.MaSP
               WHERE sp.SoLuongTon - t.SoLuongBan < 0)
    BEGIN
        DECLARE @ThongBao NVARCHAR(300);

        SELECT TOP 1 @ThongBao = CONCAT(N'Không đủ hàng: ', sp.TenSP,
                                        N' (còn ', sp.SoLuongTon, N', cần ', t.SoLuongBan, N').')
        FROM SanPham sp
        JOIN @ThayDoi t ON t.MaSP = sp.MaSP
        WHERE sp.SoLuongTon - t.SoLuongBan < 0;

        THROW 50004, @ThongBao, 1;
    END

    UPDATE sp
    SET    sp.SoLuongTon = sp.SoLuongTon - t.SoLuongBan
    FROM   SanPham sp
    JOIN   @ThayDoi t ON t.MaSP = sp.MaSP;
END
GO

-- C3. Hóa đơn: kiểm soát chuyển trạng thái, hủy hóa đơn thì hoàn lại tồn kho
--     Hợp lệ: Đang lập -> Đã thanh toán | Đang lập -> Đã hủy | Đã thanh toán -> Đã hủy (trả hàng)
CREATE OR ALTER TRIGGER trg_HoaDon_TrangThai
ON HoaDon
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN deleted  d ON d.MaHD = i.MaHD
               WHERE i.TrangThai <> d.TrangThai
                 AND NOT (   (d.TrangThai = N'Đang lập'      AND i.TrangThai IN (N'Đã thanh toán', N'Đã hủy'))
                          OR (d.TrangThai = N'Đã thanh toán' AND i.TrangThai = N'Đã hủy')))
    BEGIN
        THROW 50005, N'Chuyển trạng thái hóa đơn không hợp lệ.', 1;
    END

    -- Hóa đơn đã chốt thì không được đổi nhân viên, khách, mức giảm
    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN deleted  d ON d.MaHD = i.MaHD
               WHERE d.TrangThai <> N'Đang lập'
                 AND (   i.MaNV <> d.MaNV
                      OR ISNULL(i.MaKH, '') <> ISNULL(d.MaKH, '')
                      OR i.PhanTramGiam <> d.PhanTramGiam))
    BEGIN
        THROW 50006, N'Hóa đơn đã chốt, không được sửa thông tin.', 1;
    END

    -- Hủy hóa đơn: cộng trả lại tồn kho
    UPDATE sp
    SET    sp.SoLuongTon = sp.SoLuongTon + h.SoLuong
    FROM   SanPham sp
    JOIN  (SELECT ct.MaSP, SUM(ct.SoLuong) AS SoLuong
           FROM inserted i
           JOIN deleted  d  ON d.MaHD = i.MaHD
           JOIN ChiTietHoaDon ct ON ct.MaHD = i.MaHD
           WHERE i.TrangThai = N'Đã hủy'
             AND d.TrangThai <> N'Đã hủy'
           GROUP BY ct.MaSP) h ON h.MaSP = sp.MaSP;
END
GO

/* ==========================================================================
   PHẦN D. STORED PROCEDURE (các nghiệp vụ chính)
   ========================================================================== */

-- D1. Tạo hóa đơn mới. Nếu có SĐT khách -> tự áp mức giảm theo hạng hiện tại
CREATE OR ALTER PROCEDURE sp_TaoHoaDon
    @MaNV          VARCHAR(10),
    @SoDienThoaiKH VARCHAR(15)  = NULL,
    @PhuongThucTT  NVARCHAR(20) = N'Tiền mặt',
    @MaHD          INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaKH VARCHAR(10) = NULL, @PhanTram DECIMAL(4, 1) = 0;

    IF NOT EXISTS (SELECT 1 FROM NhanVien WHERE MaNV = @MaNV AND DangLamViec = 1)
    BEGIN
        ;THROW 50010, N'Nhân viên không tồn tại hoặc đã nghỉ việc.', 1;
    END

    IF @SoDienThoaiKH IS NOT NULL
    BEGIN
        SELECT @MaKH = MaKH, @PhanTram = ISNULL(PhanTramGiam, 0)
        FROM v_KhachHangThanhVien
        WHERE SoDienThoai = @SoDienThoaiKH;

        IF @MaKH IS NULL
        BEGIN
            ;THROW 50011, N'Không tìm thấy khách hàng có số điện thoại này.', 1;
        END
    END

    INSERT INTO HoaDon (MaNV, MaKH, PhanTramGiam, PhuongThucTT)
    VALUES (@MaNV, @MaKH, @PhanTram, @PhuongThucTT);

    SET @MaHD = SCOPE_IDENTITY();
END
GO

-- D2. Thêm sản phẩm vào hóa đơn (quét mã vạch hoặc nhập mã SP).
--     Quét lại cùng sản phẩm -> cộng dồn số lượng. Giá lấy theo giá bán hiện tại.
CREATE OR ALTER PROCEDURE sp_ThemSanPhamVaoHoaDon
    @MaHD    INT,
    @MaSPHoacMaVach VARCHAR(13),
    @SoLuong INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaSP VARCHAR(10), @GiaBan DECIMAL(12, 0);

    IF @SoLuong <= 0
    BEGIN
        ;THROW 50020, N'Số lượng phải lớn hơn 0.', 1;
    END

    SELECT @MaSP = MaSP, @GiaBan = GiaBan
    FROM SanPham
    WHERE MaSP = @MaSPHoacMaVach OR MaVach = @MaSPHoacMaVach;

    IF @MaSP IS NULL
    BEGIN
        ;THROW 50021, N'Không tìm thấy sản phẩm.', 1;
    END

    IF EXISTS (SELECT 1 FROM ChiTietHoaDon WHERE MaHD = @MaHD AND MaSP = @MaSP)
        UPDATE ChiTietHoaDon
        SET    SoLuong = SoLuong + @SoLuong
        WHERE  MaHD = @MaHD AND MaSP = @MaSP;
    ELSE
        INSERT INTO ChiTietHoaDon (MaHD, MaSP, SoLuong, DonGiaBan)
        VALUES (@MaHD, @MaSP, @SoLuong, @GiaBan);
    -- Kiểm tra tồn kho / trạng thái hóa đơn do trigger trg_ChiTietHoaDon_CapNhatTon đảm nhiệm
END
GO

-- D3. Thanh toán hóa đơn
CREATE OR ALTER PROCEDURE sp_ThanhToanHoaDon
    @MaHD INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM HoaDon WHERE MaHD = @MaHD AND TrangThai = N'Đang lập')
    BEGIN
        ;THROW 50030, N'Hóa đơn không tồn tại hoặc không ở trạng thái đang lập.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM ChiTietHoaDon WHERE MaHD = @MaHD)
    BEGIN
        ;THROW 50031, N'Hóa đơn chưa có sản phẩm nào.', 1;
    END

    UPDATE HoaDon SET TrangThai = N'Đã thanh toán' WHERE MaHD = @MaHD;

    SELECT MaHD, NgayLap, TienHang, PhanTramGiam, TienGiam, ThanhTien
    FROM v_HoaDonTongTien
    WHERE MaHD = @MaHD;
END
GO

-- D4. Hủy hóa đơn (tồn kho được hoàn lại bởi trigger trg_HoaDon_TrangThai)
CREATE OR ALTER PROCEDURE sp_HuyHoaDon
    @MaHD INT,
    @LyDo NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM HoaDon WHERE MaHD = @MaHD AND TrangThai <> N'Đã hủy')
    BEGIN
        ;THROW 50040, N'Hóa đơn không tồn tại hoặc đã bị hủy trước đó.', 1;
    END

    UPDATE HoaDon
    SET    TrangThai = N'Đã hủy',
           GhiChu    = @LyDo
    WHERE  MaHD = @MaHD;
END
GO

-- D5. Tạo phiếu nhập hàng (chi tiết thêm vào ChiTietPhieuNhap, trigger tự cộng tồn)
CREATE OR ALTER PROCEDURE sp_TaoPhieuNhap
    @MaNCC  VARCHAR(10),
    @MaNV   VARCHAR(10),
    @GhiChu NVARCHAR(200) = NULL,
    @MaPN   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO PhieuNhap (MaNCC, MaNV, GhiChu)
    VALUES (@MaNCC, @MaNV, @GhiChu);

    SET @MaPN = SCOPE_IDENTITY();
END
GO

-- D6. Báo cáo doanh thu theo ngày trong khoảng, có dòng TỔNG CỘNG (ROLLUP)
CREATE OR ALTER PROCEDURE sp_BaoCaoDoanhThu
    @TuNgay  DATE,
    @DenNgay DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @TuNgay > @DenNgay
    BEGIN
        ;THROW 50050, N'Từ ngày phải nhỏ hơn hoặc bằng đến ngày.', 1;
    END

    SELECT  CASE WHEN GROUPING(Ngay) = 1 THEN N'TỔNG CỘNG'
                 ELSE CONVERT(NVARCHAR(10), Ngay, 103) END AS Ngay,
            SUM(SoHoaDon) AS SoHoaDon,
            SUM(DoanhThu) AS DoanhThu
    FROM fn_DoanhThuTheoNgay(@TuNgay, @DenNgay)
    GROUP BY ROLLUP (Ngay)
    ORDER BY GROUPING(Ngay), MIN(Ngay);
END
GO

PRINT N'>> Đã tạo 4 function, 4 view, 3 trigger, 6 stored procedure.';
GO
