-- STEP 1: CREATE TABLES
CREATE TABLE Authors(author_id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100) NOT NULL);
CREATE TABLE Books(book_id INT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(200), isbn VARCHAR(20) UNIQUE, publication_year INT, available_copies INT DEFAULT 1);
CREATE TABLE BookAuthors(book_id INT, author_id INT, PRIMARY KEY(book_id, author_id), FOREIGN KEY(book_id) REFERENCES Books(book_id), FOREIGN KEY(author_id) REFERENCES Authors(author_id));
CREATE TABLE Members(member_id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), email VARCHAR(100) UNIQUE, join_date DATE DEFAULT CURDATE());
CREATE TABLE Loans(loan_id INT AUTO_INCREMENT PRIMARY KEY, member_id INT, book_id INT, loan_date DATE DEFAULT CURDATE(), due_date DATE, return_date DATE, FOREIGN KEY(member_id) REFERENCES Members(member_id), FOREIGN KEY(book_id) REFERENCES Books(book_id));

-- STEP 2: SAMPLE DATA
INSERT INTO Authors(name) VALUES('J.K. Rowling'),('George Orwell'),('Jane Austen'),('Mark Twain');
INSERT INTO Books(title, isbn, publication_year, available_copies) VALUES
('Harry Potter', '1111', 1997, 5),
('1984', '2222', 1949, 3),
('Pride and Prejudice', '3333', 1813, 4),
('Tom Sawyer', '4444', 1876, 2);
INSERT INTO BookAuthors(book_id, author_id) VALUES(1,1),(2,2),(3,3),(4,4);
INSERT INTO Members(name, email) VALUES('Alice','alice@example.com'),('Bob','bob@example.com'),('Charlie','charlie@example.com');
INSERT INTO Loans(member_id, book_id, loan_date, due_date, return_date) VALUES
(1,1,CURDATE() - INTERVAL 10 DAY, CURDATE() - INTERVAL 3 DAY, NULL),
(2,2,CURDATE() - INTERVAL 7 DAY, CURDATE() + INTERVAL 7 DAY, NULL),
(3,3,CURDATE() - INTERVAL 15 DAY, CURDATE() - INTERVAL 5 DAY, CURDATE() - INTERVAL 2 DAY);

-- STEP 3: CREATE VIEWS
CREATE VIEW BorrowedBooks AS
SELECT l.loan_id, m.name AS member_name, b.title AS book_title, l.loan_date, l.due_date, l.return_date
FROM Loans l
JOIN Members m ON l.member_id = m.member_id
JOIN Books b ON l.book_id = b.book_id
WHERE l.return_date IS NULL;

CREATE VIEW OverdueBooks AS
SELECT * FROM BorrowedBooks WHERE due_date < CURDATE();

-- STEP 4: DUE NOTIFICATION TRIGGER
CREATE TABLE DueNotifications (
  notification_id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT,
  book_id INT,
  notified_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER trg_due_notify AFTER INSERT ON Loans
FOR EACH ROW
BEGIN
  IF NEW.due_date < CURDATE() THEN
    INSERT INTO DueNotifications(member_id, book_id) VALUES(NEW.member_id, NEW.book_id);
  END IF;
END;
//
DELIMITER ;

-- STEP 5: RETURN UPDATE EXAMPLE
-- When member returns a book (example for loan_id = 1)
UPDATE Loans SET return_date = CURDATE() WHERE loan_id = 1;

-- STEP 6: OPTIONAL - TRIGGER TO INCREASE BOOK COPIES ON RETURN
DELIMITER //
CREATE TRIGGER trg_increase_copies AFTER UPDATE ON Loans
FOR EACH ROW
BEGIN
  IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
    UPDATE Books SET available_copies = available_copies + 1 WHERE book_id = NEW.book_id;
  END IF;
END;
//
DELIMITER ;

-- STEP 7: REPORTS

-- 1. All Borrowed Books (Not Yet Returned)
SELECT * FROM BorrowedBooks;

-- 2. All Overdue Books
SELECT * FROM OverdueBooks;

-- 3. Who Returned Which Book & When
SELECT l.loan_id, m.name AS member_name, b.title AS book_title, l.loan_date, l.due_date, l.return_date
FROM Loans l
JOIN Members m ON l.member_id = m.member_id
JOIN Books b ON l.book_id = b.book_id
WHERE l.return_date IS NOT NULL;

-- 4. Total Books Borrowed Per Member
SELECT m.name, COUNT(l.loan_id) AS total_loans
FROM Members m
JOIN Loans l ON m.member_id = l.member_id
GROUP BY m.name;

-- 5. Most Borrowed Books
SELECT b.title, COUNT(l.loan_id) AS borrow_count
FROM Books b
JOIN Loans l ON b.book_id = l.book_id
GROUP BY b.title
ORDER BY borrow_count DESC;
