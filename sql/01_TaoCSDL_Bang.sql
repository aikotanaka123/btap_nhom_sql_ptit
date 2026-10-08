/* ==========================================================================
   ĐỀ TÀI : QUẢN LÝ BÁN HÀNG CỬA HÀNG TIỆN LỢI
   HQT CSDL: Microsoft SQL Server 2019 / 2022 (chạy bằng SSMS hoặc Azure Data Studio)
   FILE 01 : Tạo cơ sở dữ liệu, các bảng, ràng buộc toàn vẹn và chỉ mục
   Thứ tự chạy: 01 -> 02 -> 03 -> 04 -> 05
   ========================================================================== */

USE master;
GO

-- Xóa CSDL cũ (nếu có) để chạy lại từ đầu
IF DB_ID(N'QLCuaHangTienLoi') IS NOT NULL
BEGIN
    ALTER DATABASE QLCuaHangTienLoi SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QLCuaHangTienLoi;
END
GO

CREATE DATABASE QLCuaHangTienLoi;
GO

USE QLCuaHangTienLoi;
GO

/* --------------------------------------------------------------------------
   1. NHÓM BẢNG NHÂN SỰ
   -------------------------------------------------------------------------- */

-- Chức vụ: lương cơ bản phụ thuộc vào chức vụ, không phụ thuộc từng nhân viên
CREATE TABLE ChucVu (
    MaCV        VARCHAR(10)    NOT NULL CONSTRAINT PK_ChucVu PRIMARY KEY,
    TenCV       NVARCHAR(50)   NOT NULL CONSTRAINT UQ_ChucVu_TenCV UNIQUE,
    LuongCoBan  DECIMAL(12, 0) NOT NULL CONSTRAINT CK_ChucVu_LuongCoBan CHECK (LuongCoBan > 0)
);
GO

CREATE TABLE NhanVien (
    MaNV        VARCHAR(10)    NOT NULL CONSTRAINT PK_NhanVien PRIMARY KEY,
    HoTen       NVARCHAR(100)  NOT NULL,
    GioiTinh    NVARCHAR(3)    NOT NULL CONSTRAINT CK_NhanVien_GioiTinh CHECK (GioiTinh IN (N'Nam', N'Nữ')),
    NgaySinh    DATE           NOT NULL,
    SoDienThoai VARCHAR(15)    NOT NULL CONSTRAINT UQ_NhanVien_SoDienThoai UNIQUE,
    DiaChi      NVARCHAR(200)  NULL,
    NgayVaoLam  DATE           NOT NULL CONSTRAINT DF_NhanVien_NgayVaoLam DEFAULT (CAST(GETDATE() AS DATE)),
    MaCV        VARCHAR(10)    NOT NULL CONSTRAINT FK_NhanVien_ChucVu REFERENCES ChucVu (MaCV),
    DangLamViec BIT            NOT NULL CONSTRAINT DF_NhanVien_DangLamViec DEFAULT (1),
    -- Nhân viên phải đủ 18 tuổi tại ngày vào làm
    CONSTRAINT CK_NhanVien_DuTuoi CHECK (DATEADD(YEAR, 18, NgaySinh) <= NgayVaoLam)
);
GO

/* --------------------------------------------------------------------------
   2. NHÓM BẢNG KHÁCH HÀNG
   -------------------------------------------------------------------------- */

-- Hạng thành viên: xác định theo điểm tích lũy (1 điểm = 10.000đ đã chi)
CREATE TABLE HangThanhVien (
    MaHang       VARCHAR(10)   NOT NULL CONSTRAINT PK_HangThanhVien PRIMARY KEY,
    TenHang      NVARCHAR(30)  NOT NULL CONSTRAINT UQ_HangThanhVien_TenHang UNIQUE,
    DiemToiThieu INT           NOT NULL CONSTRAINT UQ_HangThanhVien_DiemToiThieu UNIQUE
                                        CONSTRAINT CK_HangThanhVien_DiemToiThieu CHECK (DiemToiThieu >= 0),
    PhanTramGiam DECIMAL(4, 1) NOT NULL CONSTRAINT CK_HangThanhVien_PhanTramGiam CHECK (PhanTramGiam BETWEEN 0 AND 50)
);
GO

-- Khách hàng thành viên. KHÔNG lưu điểm và hạng ở đây vì đó là dữ liệu dẫn xuất
-- (tính từ hóa đơn) -> tránh phụ thuộc bắc cầu, xem view v_KhachHangThanhVien
CREATE TABLE KhachHang (
    MaKH        VARCHAR(10)   NOT NULL CONSTRAINT PK_KhachHang PRIMARY KEY,
    HoTen       NVARCHAR(100) NOT NULL,
    SoDienThoai VARCHAR(15)   NOT NULL CONSTRAINT UQ_KhachHang_SoDienThoai UNIQUE,
    NgayDangKy  DATE          NOT NULL CONSTRAINT DF_KhachHang_NgayDangKy DEFAULT (CAST(GETDATE() AS DATE))
);
GO

/* --------------------------------------------------------------------------
   3. NHÓM BẢNG HÀNG HÓA
   -------------------------------------------------------------------------- */

CREATE TABLE DanhMuc (
    MaDM  VARCHAR(10)   NOT NULL CONSTRAINT PK_DanhMuc PRIMARY KEY,
    TenDM NVARCHAR(50)  NOT NULL CONSTRAINT UQ_DanhMuc_TenDM UNIQUE,
    MoTa  NVARCHAR(200) NULL
);
GO

CREATE TABLE NhaCungCap (
    MaNCC       VARCHAR(10)   NOT NULL CONSTRAINT PK_NhaCungCap PRIMARY KEY,
    TenNCC      NVARCHAR(150) NOT NULL,
    SoDienThoai VARCHAR(15)   NOT NULL CONSTRAINT UQ_NhaCungCap_SoDienThoai UNIQUE,
    Email       VARCHAR(100)  NULL CONSTRAINT CK_NhaCungCap_Email CHECK (Email LIKE '%_@_%._%'),
    DiaChi      NVARCHAR(200) NULL
);
GO

-- SoLuongTon được cập nhật TỰ ĐỘNG bởi trigger khi nhập / bán / hủy hóa đơn
CREATE TABLE SanPham (
    MaSP          VARCHAR(10)    NOT NULL CONSTRAINT PK_SanPham PRIMARY KEY,
    MaVach        VARCHAR(13)    NOT NULL CONSTRAINT UQ_SanPham_MaVach UNIQUE,
    TenSP         NVARCHAR(150)  NOT NULL,
    MaDM          VARCHAR(10)    NOT NULL CONSTRAINT FK_SanPham_DanhMuc REFERENCES DanhMuc (MaDM),
    DonViTinh     NVARCHAR(20)   NOT NULL,
    GiaBan        DECIMAL(12, 0) NOT NULL CONSTRAINT CK_SanPham_GiaBan CHECK (GiaBan > 0),
    SoLuongTon    INT            NOT NULL CONSTRAINT DF_SanPham_SoLuongTon DEFAULT (0)
                                          CONSTRAINT CK_SanPham_SoLuongTon CHECK (SoLuongTon >= 0),
    TonToiThieu   INT            NOT NULL CONSTRAINT DF_SanPham_TonToiThieu DEFAULT (5)
                                          CONSTRAINT CK_SanPham_TonToiThieu CHECK (TonToiThieu >= 0),
    DangKinhDoanh BIT            NOT NULL CONSTRAINT DF_SanPham_DangKinhDoanh DEFAULT (1)
);
GO

/* --------------------------------------------------------------------------
   4. NHÓM BẢNG NHẬP HÀNG
   -------------------------------------------------------------------------- */

CREATE TABLE PhieuNhap (
    MaPN     INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_PhieuNhap PRIMARY KEY,
    NgayNhap DATETIME2(0)       NOT NULL CONSTRAINT DF_PhieuNhap_NgayNhap DEFAULT (SYSDATETIME()),
    MaNCC    VARCHAR(10)        NOT NULL CONSTRAINT FK_PhieuNhap_NhaCungCap REFERENCES NhaCungCap (MaNCC),
    MaNV     VARCHAR(10)        NOT NULL CONSTRAINT FK_PhieuNhap_NhanVien REFERENCES NhanVien (MaNV),
    GhiChu   NVARCHAR(200)      NULL
);
GO

-- Giá nhập nằm ở chi tiết phiếu nhập vì mỗi lần nhập có thể có giá khác nhau
CREATE TABLE ChiTietPhieuNhap (
    MaPN       INT            NOT NULL CONSTRAINT FK_CTPN_PhieuNhap REFERENCES PhieuNhap (MaPN),
    MaSP       VARCHAR(10)    NOT NULL CONSTRAINT FK_CTPN_SanPham REFERENCES SanPham (MaSP),
    SoLuong    INT            NOT NULL CONSTRAINT CK_CTPN_SoLuong CHECK (SoLuong > 0),
    DonGiaNhap DECIMAL(12, 0) NOT NULL CONSTRAINT CK_CTPN_DonGiaNhap CHECK (DonGiaNhap > 0),
    HanSuDung  DATE           NULL,
    CONSTRAINT PK_ChiTietPhieuNhap PRIMARY KEY (MaPN, MaSP)
);
GO

/* --------------------------------------------------------------------------
   5. NHÓM BẢNG BÁN HÀNG
   -------------------------------------------------------------------------- */

-- PhanTramGiam: lưu lại mức giảm TẠI THỜI ĐIỂM BÁN (hạng khách có thể thay đổi sau này)
-- Tổng tiền KHÔNG lưu trong bảng (dữ liệu dẫn xuất) -> tính qua view v_HoaDonTongTien
CREATE TABLE HoaDon (
    MaHD         INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_HoaDon PRIMARY KEY,
    NgayLap      DATETIME2(0)       NOT NULL CONSTRAINT DF_HoaDon_NgayLap DEFAULT (SYSDATETIME()),
    MaNV         VARCHAR(10)        NOT NULL CONSTRAINT FK_HoaDon_NhanVien REFERENCES NhanVien (MaNV),
    MaKH         VARCHAR(10)        NULL     CONSTRAINT FK_HoaDon_KhachHang REFERENCES KhachHang (MaKH), -- NULL = khách lẻ
    PhanTramGiam DECIMAL(4, 1)      NOT NULL CONSTRAINT DF_HoaDon_PhanTramGiam DEFAULT (0)
                                             CONSTRAINT CK_HoaDon_PhanTramGiam CHECK (PhanTramGiam BETWEEN 0 AND 50),
    PhuongThucTT NVARCHAR(20)       NOT NULL CONSTRAINT DF_HoaDon_PhuongThucTT DEFAULT (N'Tiền mặt')
                                             CONSTRAINT CK_HoaDon_PhuongThucTT
                                             CHECK (PhuongThucTT IN (N'Tiền mặt', N'Chuyển khoản', N'Thẻ', N'Ví điện tử')),
    TrangThai    NVARCHAR(20)       NOT NULL CONSTRAINT DF_HoaDon_TrangThai DEFAULT (N'Đang lập')
                                             CONSTRAINT CK_HoaDon_TrangThai
                                             CHECK (TrangThai IN (N'Đang lập', N'Đã thanh toán', N'Đã hủy')),
    GhiChu       NVARCHAR(200)      NULL
);
GO

-- DonGiaBan: giá bán TẠI THỜI ĐIỂM BÁN (giá trong SanPham có thể đổi sau này)
CREATE TABLE ChiTietHoaDon (
    MaHD      INT            NOT NULL CONSTRAINT FK_CTHD_HoaDon REFERENCES HoaDon (MaHD),
    MaSP      VARCHAR(10)    NOT NULL CONSTRAINT FK_CTHD_SanPham REFERENCES SanPham (MaSP),
    SoLuong   INT            NOT NULL CONSTRAINT CK_CTHD_SoLuong CHECK (SoLuong > 0),
    DonGiaBan DECIMAL(12, 0) NOT NULL CONSTRAINT CK_CTHD_DonGiaBan CHECK (DonGiaBan > 0),
    CONSTRAINT PK_ChiTietHoaDon PRIMARY KEY (MaHD, MaSP)
);
GO

/* --------------------------------------------------------------------------
   6. CHỈ MỤC (INDEX) hỗ trợ các truy vấn thường dùng
   -------------------------------------------------------------------------- */
CREATE NONCLUSTERED INDEX IX_HoaDon_NgayLap      ON HoaDon (NgayLap) INCLUDE (TrangThai, MaNV, MaKH);
CREATE NONCLUSTERED INDEX IX_HoaDon_MaKH         ON HoaDon (MaKH);
CREATE NONCLUSTERED INDEX IX_ChiTietHoaDon_MaSP  ON ChiTietHoaDon (MaSP);
CREATE NONCLUSTERED INDEX IX_ChiTietPhieuNhap_MaSP ON ChiTietPhieuNhap (MaSP);
CREATE NONCLUSTERED INDEX IX_SanPham_MaDM        ON SanPham (MaDM);
CREATE NONCLUSTERED INDEX IX_NhanVien_MaCV       ON NhanVien (MaCV);
GO

PRINT N'>> Đã tạo CSDL QLCuaHangTienLoi với 11 bảng.';
GO
