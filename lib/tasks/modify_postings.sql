ALTER TABLE postings ADD COLUMN effective_date DATE DEFAULT NULL;
UPDATE postings p SET p.effective_date = (SELECT j.date FROM journals j WHERE j.id = p.journal_id); 
ALTER TABLE postings MODIFY COLUMN effective_date DATE NOT NULL;