CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    role VARCHAR(32) NOT NULL CHECK (role IN ('READER', 'LIBRARIAN', 'ADMIN')),
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'BLOCKED', 'DEACTIVATED')),
    blocked_until TIMESTAMP,
    block_reason TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    authors VARCHAR(500) NOT NULL,
    publication_year INT CHECK (publication_year IS NULL OR publication_year > 0),
    isbn_or_code VARCHAR(100),
    department_or_subject VARCHAR(255),
    description TEXT,
    archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE book_copies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE RESTRICT,
    inventory_number VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(32) NOT NULL DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'RESERVED', 'LOANED', 'WRITTEN_OFF')),
    condition_note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE RESTRICT,
    copy_id UUID REFERENCES book_copies(id) ON DELETE RESTRICT,
    status VARCHAR(32) NOT NULL DEFAULT 'REQUESTED' CHECK (status IN ('REQUESTED', 'ACTIVE', 'RETURNED', 'OVERDUE', 'REJECTED')),
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    issued_at TIMESTAMP,
    due_date DATE,
    returned_at TIMESTAMP,
    extensions_count INT NOT NULL DEFAULT 0 CHECK (extensions_count >= 0 AND extensions_count <= 2),
    librarian_note TEXT
);

CREATE TABLE queue_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    reserved_copy_id UUID REFERENCES book_copies(id) ON DELETE SET NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'WAITING' CHECK (status IN ('WAITING', 'READY_FOR_PICKUP', 'COMPLETED', 'CANCELLED')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notified_at TIMESTAMP
);

CREATE INDEX idx_book_copies_book_id ON book_copies(book_id);
CREATE INDEX idx_book_copies_status ON book_copies(status);
CREATE INDEX idx_loans_user_id ON loans(user_id);
CREATE INDEX idx_loans_book_id ON loans(book_id);
CREATE INDEX idx_loans_copy_id ON loans(copy_id);
CREATE INDEX idx_loans_status_due_date ON loans(status, due_date);
CREATE INDEX idx_queue_entries_book_status_created ON queue_entries(book_id, status, created_at);