-- Tạo Database nếu chưa có
CREATE DATABASE IF NOT EXISTS movie_ticket_booking DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE movie_ticket_booking;

-- 1. Bảng users (Người dùng / Quản trị viên)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(255),
    role VARCHAR(50) DEFAULT 'USER' -- Enum: USER, ADMIN
);

-- 2. Bảng genres (Thể loại phim)
CREATE TABLE IF NOT EXISTS genres (
    id SMALLINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- 3. Bảng movies (Phim)
CREATE TABLE IF NOT EXISTS movies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    director_name VARCHAR(255),
    actors_name VARCHAR(255),
    description TEXT,
    duration INT,
    rating DOUBLE DEFAULT 0.0,
    country VARCHAR(255),
    image_url VARCHAR(500),
    movie_status VARCHAR(50), -- Enum: COMING_SOON, NOW_SHOWING, STOPPED_SHOWING
    show_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bảng movie_genres (Bảng trung gian N-N giữa Movies và Genres)
CREATE TABLE IF NOT EXISTS movie_genres (
    movie_id INT NOT NULL,
    genre_id SMALLINT NOT NULL,
    PRIMARY KEY (movie_id, genre_id),
    CONSTRAINT fk_mg_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE,
    CONSTRAINT fk_mg_genre FOREIGN KEY (genre_id) REFERENCES genres (id) ON DELETE CASCADE
);

-- 5. Bảng cinemas (Rạp chiếu phim)
CREATE TABLE IF NOT EXISTS cinemas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL
);

-- 6. Bảng rooms (Phòng chiếu)
CREATE TABLE IF NOT EXISTS rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    number_of_columns INT NOT NULL,
    number_of_rows INT NOT NULL,
    description TEXT,
    cinema_id INT,
    CONSTRAINT fk_rooms_cinema FOREIGN KEY (cinema_id) REFERENCES cinemas (id) ON DELETE CASCADE
);

-- 7. Bảng seats (Ghế ngồi sơ đồ tĩnh của phòng)
CREATE TABLE IF NOT EXISTS seats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    seat_name VARCHAR(50) NOT NULL,
    type VARCHAR(50) DEFAULT 'STANDARD', -- Enum: STANDARD, COUPLE, VIP
    room_id INT,
    CONSTRAINT fk_seats_room FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE CASCADE
);

-- 8. Bảng showtimes (Suất chiếu phim)
CREATE TABLE IF NOT EXISTS showtimes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    price DECIMAL(10, 2) NOT NULL,
    start_time DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    cinema_id INT,
    room_id INT,
    movie_id INT,
    CONSTRAINT fk_showtimes_cinema FOREIGN KEY (cinema_id) REFERENCES cinemas (id) ON DELETE CASCADE,
    CONSTRAINT fk_showtimes_room FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE CASCADE,
    CONSTRAINT fk_showtimes_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE
);

-- 9. Bảng showtime_seats (Ghế theo từng suất chiếu - Trạng thái trống/đã đặt)
CREATE TABLE IF NOT EXISTS showtime_seats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    status VARCHAR(50) DEFAULT 'AVAILABLE', -- Enum: AVAILABLE, BOOKED, RESERVED
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    seat_id INT,
    showtime_id INT,
    CONSTRAINT fk_sts_seat FOREIGN KEY (seat_id) REFERENCES seats (id) ON DELETE CASCADE,
    CONSTRAINT fk_sts_showtime FOREIGN KEY (showtime_id) REFERENCES showtimes (id) ON DELETE CASCADE
);

-- 10. Bảng tickets (Vé xem phim / Đơn đặt vé)
CREATE TABLE IF NOT EXISTS tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uid VARCHAR(255),
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50), -- Enum: PENDING, CONFIRMED, CANCELLED
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    user_id INT,
    showtime_id INT,
    CONSTRAINT fk_tickets_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_tickets_showtime FOREIGN KEY (showtime_id) REFERENCES showtimes (id) ON DELETE CASCADE
);

-- 11. Bảng ticket_seats (Chi tiết ghế của từng vé đặt)
CREATE TABLE IF NOT EXISTS ticket_seats (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT,
    showtime_seat_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    cancelled_at DATETIME,
    CONSTRAINT fk_ts_ticket FOREIGN KEY (ticket_id) REFERENCES tickets (id) ON DELETE CASCADE,
    CONSTRAINT fk_ts_showtime_seat FOREIGN KEY (showtime_seat_id) REFERENCES showtime_seats (id) ON DELETE CASCADE
);

-- 12. Bảng payments (Thanh toán giao dịch)
CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uid VARCHAR(255),
    ticket_id INT NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    method VARCHAR(50), -- Enum: VNPAY, MOMO, CREDIT_CARD, BANK_TRANSFER, CASH
    status VARCHAR(50), -- Enum: PENDING, SUCCESS, FAILED, REFUNDED
    transaction_id VARCHAR(255),
    response_code VARCHAR(100),
    paid_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_payments_ticket FOREIGN KEY (ticket_id) REFERENCES tickets (id) ON DELETE CASCADE
);

USE movie_ticket_booking;

-- 1. Thêm dữ liệu mẫu Thể loại (genres)
INSERT INTO genres (id, name) VALUES 
(1, 'Action'),
(2, 'Science Fiction'),
(3, 'Romance'),
(4, 'Horror'),
(5, 'Comedy'),
(6, 'Animation'),
(7, 'Psychological');

-- 2. Thêm dữ liệu mẫu Phim (movies)
INSERT INTO movies (id, name, director_name, actors_name, description, duration, rating, country, image_url, movie_status, show_at, created_at) VALUES 
(1, 'Avatar: The Way of Water', 'James Cameron', 'Sam Worthington, Zoe Saldaña', 'Set more than a decade after the events of the first film.', 192, 8.8, 'USA', 'https://images.unsplash.com/photo-1536440136628-849c177e76a1', 'NOW_SHOWING', '2026-08-01 10:00:00', NOW()),
(2, 'Oppenheimer', 'Christopher Nolan', 'Cillian Murphy, Emily Blunt', 'The story of J. Robert Oppenheimer.', 180, 8.9, 'USA', 'https://images.unsplash.com/photo-1440404653325-ab127d49abc1', 'NOW_SHOWING', '2026-08-02 14:00:00', NOW()),
(3, 'Minions: The Rise of Gru', 'Chris Renaud', 'Steve Carell, Kristen Wiig', 'Gru and the Minions return for a new adventure.', 94, 8.2, 'USA', 'https://images.unsplash.com/photo-1563089145-599997674d42', 'COMING_SOON', '2026-08-15 09:00:00', NOW());

-- 3. Gán thể loại cho phim (movie_genres)
INSERT INTO movie_genres (movie_id, genre_id) VALUES 
(1, 1), (1, 2), -- Avatar: Action + Science Fiction
(2, 7),         -- Oppenheimer: Psychological
(3, 5), (3, 6); -- Minions: Comedy + Animation

-- 4. Thêm dữ liệu mẫu Rạp chiếu (cinemas)
INSERT INTO cinemas (id, name, address) VALUES 
(1, 'CinePrime Vincom Landmark 81', 'Binh Thanh District, TP.HCM'),
(2, 'CinePrime Paragon', '7 District, TP.HCM');

-- 5. Thêm dữ liệu mẫu Phòng chiếu (rooms)
INSERT INTO rooms (id, name, number_of_columns, number_of_rows, description, cinema_id) VALUES 
(1, 'Phòng 01 (IMAX 3D)', 8, 6, 'Premium, large-format IMAX-standard screening room', 1),
(2, 'Phòng 02 (2D Atmos)', 8, 6, 'Premium, large-format IMAX-standard screening room', 1),
(3, 'Phòng VIP 01', 6, 4, 'Premium, large-format IMAX-standard screening room', 2);

-- 6. Thêm dữ liệu Ghế đầy đủ (seats) cho Phòng 01 (6 hàng x 8 cột = 48 ghế)
INSERT INTO seats (seat_name, type, room_id) VALUES 
('A1', 'STANDARD', 1), ('A2', 'STANDARD', 1), ('A3', 'STANDARD', 1), ('A4', 'STANDARD', 1), ('A5', 'STANDARD', 1), ('A6', 'STANDARD', 1), ('A7', 'STANDARD', 1), ('A8', 'STANDARD', 1),
('B1', 'STANDARD', 1), ('B2', 'STANDARD', 1), ('B3', 'STANDARD', 1), ('B4', 'STANDARD', 1), ('B5', 'STANDARD', 1), ('B6', 'STANDARD', 1), ('B7', 'STANDARD', 1), ('B8', 'STANDARD', 1),
('C1', 'VIP', 1),      ('C2', 'VIP', 1),      ('C3', 'VIP', 1),      ('C4', 'VIP', 1),      ('C5', 'VIP', 1),      ('C6', 'VIP', 1),      ('C7', 'VIP', 1),      ('C8', 'VIP', 1),
('D1', 'VIP', 1),      ('D2', 'VIP', 1),      ('D3', 'VIP', 1),      ('D4', 'VIP', 1),      ('D5', 'VIP', 1),      ('D6', 'VIP', 1),      ('D7', 'VIP', 1),      ('D8', 'VIP', 1),
('E1', 'VIP', 1),      ('E2', 'VIP', 1),      ('E3', 'VIP', 1),      ('E4', 'VIP', 1),      ('E5', 'VIP', 1),      ('E6', 'VIP', 1),      ('E7', 'VIP', 1),      ('E8', 'VIP', 1),
('F1', 'COUPLE', 1),   ('F2', 'COUPLE', 1),   ('F3', 'COUPLE', 1),   ('F4', 'COUPLE', 1),   ('F5', 'COUPLE', 1),   ('F6', 'COUPLE', 1),   ('F7', 'COUPLE', 1),   ('F8', 'COUPLE', 1);

-- 7. Thêm dữ liệu Ghế đầy đủ (seats) cho Phòng 02 (6 hàng x 8 cột = 48 ghế)
INSERT INTO seats (seat_name, type, room_id) VALUES 
('A1', 'STANDARD', 2), ('A2', 'STANDARD', 2), ('A3', 'STANDARD', 2), ('A4', 'STANDARD', 2), ('A5', 'STANDARD', 2), ('A6', 'STANDARD', 2), ('A7', 'STANDARD', 2), ('A8', 'STANDARD', 2),
('B1', 'STANDARD', 2), ('B2', 'STANDARD', 2), ('B3', 'STANDARD', 2), ('B4', 'STANDARD', 2), ('B5', 'STANDARD', 2), ('B6', 'STANDARD', 2), ('B7', 'STANDARD', 2), ('B8', 'STANDARD', 2),
('C1', 'VIP', 2),      ('C2', 'VIP', 2),      ('C3', 'VIP', 2),      ('C4', 'VIP', 2),      ('C5', 'VIP', 2),      ('C6', 'VIP', 2),      ('C7', 'VIP', 2),      ('C8', 'VIP', 2),
('D1', 'VIP', 2),      ('D2', 'VIP', 2),      ('D3', 'VIP', 2),      ('D4', 'VIP', 2),      ('D5', 'VIP', 2),      ('D6', 'VIP', 2),      ('D7', 'VIP', 2),      ('D8', 'VIP', 2),
('E1', 'VIP', 2),      ('E2', 'VIP', 2),      ('E3', 'VIP', 2),      ('E4', 'VIP', 2),      ('E5', 'VIP', 2),      ('E6', 'VIP', 2),      ('E7', 'VIP', 2),      ('E8', 'VIP', 2),
('F1', 'COUPLE', 2),   ('F2', 'COUPLE', 2),   ('F3', 'COUPLE', 2),   ('F4', 'COUPLE', 2),   ('F5', 'COUPLE', 2),   ('F6', 'COUPLE', 2),   ('F7', 'COUPLE', 2),   ('F8', 'COUPLE', 2);

-- 8. Thêm dữ liệu Ghế đầy đủ (seats) cho Phòng 03 (4 hàng x 6 cột = 24 ghế)
INSERT INTO seats (seat_name, type, room_id) VALUES 
('A1', 'VIP', 3), ('A2', 'VIP', 3), ('A3', 'VIP', 3), ('A4', 'VIP', 3), ('A5', 'VIP', 3), ('A6', 'VIP', 3),
('B1', 'VIP', 3), ('B2', 'VIP', 3), ('B3', 'VIP', 3), ('B4', 'VIP', 3), ('B5', 'VIP', 3), ('B6', 'VIP', 3),
('C1', 'VIP', 3), ('C2', 'VIP', 3), ('C3', 'VIP', 3), ('C4', 'VIP', 3), ('C5', 'VIP', 3), ('C6', 'VIP', 3),
('D1', 'COUPLE', 3), ('D2', 'COUPLE', 3), ('D3', 'COUPLE', 3), ('D4', 'COUPLE', 3), ('D5', 'COUPLE', 3), ('D6', 'COUPLE', 3);

-- 9. Thêm dữ liệu Suất chiếu mẫu (showtimes)
INSERT INTO showtimes (id, price, start_time, created_at, cinema_id, room_id, movie_id) VALUES 
(1, 90000.00, '2026-11-20 18:30:00', NOW(), 1, 1, 1),
(2, 90000.00, '2026-11-20 21:00:00', NOW(), 1, 2, 1),
(3, 110000.00, '2026-11-20 19:30:00', NOW(), 1, 1, 2),
(4, 120000.00, '2026-11-20 20:00:00', NOW(), 2, 3, 2);

-- 10. Thêm dữ liệu Trạng thái ghế cho Suất chiếu 1 (showtime_seats)
INSERT INTO showtime_seats (showtime_id, seat_id, status, created_at, updated_at)
SELECT 1, s.id, 'AVAILABLE', NOW(), NOW() FROM seats s WHERE s.room_id = 1;

-- 11. Thêm dữ liệu Trạng thái ghế cho Suất chiếu 2 (showtime_seats)
INSERT INTO showtime_seats (showtime_id, seat_id, status, created_at, updated_at)
SELECT 2, s.id, 'AVAILABLE', NOW(), NOW() FROM seats s WHERE s.room_id = 2;

-- 12. Thêm dữ liệu Trạng thái ghế cho Suất chiếu 3 (showtime_seats)
INSERT INTO showtime_seats (showtime_id, seat_id, status, created_at, updated_at)
SELECT 3, s.id, 'AVAILABLE', NOW(), NOW() FROM seats s WHERE s.room_id = 1;

-- 13. Thêm dữ liệu Trạng thái ghế cho Suất chiếu 4 (showtime_seats)
INSERT INTO showtime_seats (showtime_id, seat_id, status, created_at, updated_at)
SELECT 4, s.id, 'AVAILABLE', NOW(), NOW() FROM seats s WHERE s.room_id = 3;
