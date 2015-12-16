CREATE SEQUENCE id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: transactions; Type: TABLE; Schema: public; Owner: noxx; Tablespace: 
--
CREATE TABLE test_table (
    id integer DEFAULT nextval('id_seq'::regclass) NOT NULL, 
    account character varying(50) NOT NULL,
    amount numeric(24,2) NOT NULL,
    currency character(3) NOT NULL,
    card_number character varying(21) NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    finished_at timestamp(6) without time zone
);
