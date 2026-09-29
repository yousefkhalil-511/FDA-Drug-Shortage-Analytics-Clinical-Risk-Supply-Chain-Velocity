-- Staging table to hold the raw file
CREATE TABLE staging_drug_shortages (
    raw_payload JSONB
);

-- Target structured table
CREATE TABLE drug_shortages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    package_ndc TEXT,
    generic_name TEXT,
    company_name TEXT,
    dosage_form TEXT,
    presentation TEXT,
    status TEXT,
    availability TEXT,
    shortage_reason TEXT,
    update_type TEXT,
    initial_posting_date DATE,
    update_date DATE,
    discontinued_date DATE,
    contact_info TEXT,
    related_info TEXT,
    therapeutic_category TEXT[],
    openfda JSONB
);

-- Index commonly filtered fields
CREATE INDEX idx_drug_shortages_generic ON drug_shortages(generic_name);
CREATE INDEX idx_drug_shortages_status ON drug_shortages(status);
CREATE INDEX idx_drug_shortages_openfda ON drug_shortages USING GIN (openfda);

-- Load the JSON into PostgreSQL
INSERT INTO staging_drug_shortages (raw_payload)
SELECT pg_read_file('D:/Yousef Khalil/Data Analysis Content/Week 7/Post 2/drug-shortages-0001-of-0001.json')::jsonb;

-- Run this query to expand the results JSON array, format dates with to_date(), 
-- convert therapeutic_category to a PostgreSQL text[], and isolate openfda
INSERT INTO drug_shortages (
    package_ndc,
    generic_name,
    company_name,
    dosage_form,
    presentation,
    status,
    availability,
    shortage_reason,
    update_type,
    initial_posting_date,
    update_date,
    discontinued_date,
    contact_info,
    related_info,
    therapeutic_category,
    openfda
)
SELECT
    elem->>'package_ndc',
    elem->>'generic_name',
    elem->>'company_name',
    elem->>'dosage_form',
    elem->>'presentation',
    elem->>'status',
    elem->>'availability',
    elem->>'shortage_reason',
    elem->>'update_type',
    to_date(elem->>'initial_posting_date', 'MM/DD/YYYY'),
    to_date(elem->>'update_date', 'MM/DD/YYYY'),
    to_date(elem->>'discontinued_date', 'MM/DD/YYYY'),
    elem->>'contact_info',
    elem->>'related_info',
    ARRAY(
        SELECT jsonb_array_elements_text(elem->'therapeutic_category')
    ),
    elem->'openfda'
FROM staging_drug_shortages,
     jsonb_array_elements(raw_payload->'results') AS elem;

-- Clean up the staging table
TRUNCATE staging_drug_shortages;
