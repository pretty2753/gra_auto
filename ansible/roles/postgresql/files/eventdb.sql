CREATE TABLE IF NOT EXISTS event_data(
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    receipt_no VARCHAR(100) UNIQUE NOT NULL,
    result VARCHAR(50) NOT NULL
);

GRANT ALL PRIVILEGES ON DATABASE eventdb TO eventuser;

INSERT INTO event_data (name, receipt_no, result)
VALUES
('홍길동', 'A001', '당첨'),
('김철수', 'A002', '미당첨'),
('이영희', 'A003', '당첨')
ON CONFLICT (receipt_no) DO NOTHING;