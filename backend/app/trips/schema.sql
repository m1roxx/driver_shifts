CREATE TABLE IF NOT EXISTS trips (
    id         text        PRIMARY KEY,
    started_at timestamptz NOT NULL,
    ended_at   timestamptz NOT NULL,
    amount     integer     NOT NULL,
    payment    text        NOT NULL,
    commission integer     NOT NULL,
    CONSTRAINT trips_amount_positive CHECK (amount > 0),
    CONSTRAINT trips_end_after_start CHECK (ended_at > started_at),
    CONSTRAINT trips_commission_within_amount CHECK (commission BETWEEN 0 AND amount),
    CONSTRAINT trips_payment_known CHECK (payment IN ('cash', 'card'))
);

CREATE INDEX IF NOT EXISTS trips_started_at_idx ON trips (started_at);
