--
-- PostgreSQL database dump
--

\restrict e8WxpaI3trWc3E9TBfeB6mtt4zq3NfMQjXLlkIAOj1Pj6EVlcP4tJ9RLgG5kTr4

-- Dumped from database version 15.17 (Debian 15.17-1.pgdg13+1)
-- Dumped by pg_dump version 15.17 (Debian 15.17-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: autoservice_schema; Type: SCHEMA; Schema: -; Owner: admin
--

CREATE SCHEMA autoservice_schema;


ALTER SCHEMA autoservice_schema OWNER TO admin;

--
-- Name: pageinspect; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pageinspect WITH SCHEMA public;


--
-- Name: EXTENSION pageinspect; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pageinspect IS 'inspect the contents of database pages at a low level';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: autopart; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.autopart (
    id integer NOT NULL,
    name character varying NOT NULL,
    purchase_id integer,
    task_id integer
);


ALTER TABLE autoservice_schema.autopart OWNER TO admin;

--
-- Name: autopart_id_seq; Type: SEQUENCE; Schema: autoservice_schema; Owner: admin
--

CREATE SEQUENCE autoservice_schema.autopart_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE autoservice_schema.autopart_id_seq OWNER TO admin;

--
-- Name: autopart_id_seq; Type: SEQUENCE OWNED BY; Schema: autoservice_schema; Owner: admin
--

ALTER SEQUENCE autoservice_schema.autopart_id_seq OWNED BY autoservice_schema.autopart.id;


--
-- Name: box; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.box (
    id integer NOT NULL,
    id_branch_office integer NOT NULL,
    box_type character varying NOT NULL
);


ALTER TABLE autoservice_schema.box OWNER TO admin;

--
-- Name: box_id_seq; Type: SEQUENCE; Schema: autoservice_schema; Owner: admin
--

CREATE SEQUENCE autoservice_schema.box_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE autoservice_schema.box_id_seq OWNER TO admin;

--
-- Name: box_id_seq; Type: SEQUENCE OWNED BY; Schema: autoservice_schema; Owner: admin
--

ALTER SEQUENCE autoservice_schema.box_id_seq OWNED BY autoservice_schema.box.id;


--
-- Name: branch_office; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.branch_office (
    id integer NOT NULL,
    address character varying NOT NULL,
    phone_number character varying NOT NULL
);


ALTER TABLE autoservice_schema.branch_office OWNER TO admin;

--
-- Name: branch_office_id_seq; Type: SEQUENCE; Schema: autoservice_schema; Owner: admin
--

CREATE SEQUENCE autoservice_schema.branch_office_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE autoservice_schema.branch_office_id_seq OWNER TO admin;

--
-- Name: branch_office_id_seq; Type: SEQUENCE OWNED BY; Schema: autoservice_schema; Owner: admin
--

ALTER SEQUENCE autoservice_schema.branch_office_id_seq OWNED BY autoservice_schema.branch_office.id;


--
-- Name: branch_office_manager; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.branch_office_manager (
    branch_office_id integer NOT NULL,
    manager_id integer NOT NULL
);


ALTER TABLE autoservice_schema.branch_office_manager OWNER TO admin;

--
-- Name: car; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.car (
    vin character varying(17) NOT NULL,
    model character varying NOT NULL,
    plate_number character varying NOT NULL,
    status character varying NOT NULL,
    box_id integer NOT NULL,
    specs jsonb
);


ALTER TABLE autoservice_schema.car OWNER TO admin;

--
-- Name: customer; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.customer (
    id integer NOT NULL,
    full_name character varying NOT NULL,
    phone_number character varying NOT NULL,
    tags text[]
);


ALTER TABLE autoservice_schema.customer OWNER TO admin;

--
-- Name: customer_id_seq; Type: SEQUENCE; Schema: autoservice_schema; Owner: admin
--

CREATE SEQUENCE autoservice_schema.customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE autoservice_schema.customer_id_seq OWNER TO admin;

--
-- Name: customer_id_seq; Type: SEQUENCE OWNED BY; Schema: autoservice_schema; Owner: admin
--

ALTER SEQUENCE autoservice_schema.customer_id_seq OWNED BY autoservice_schema.customer.id;


--
-- Name: order; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema."order" (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    creation_date timestamp without time zone NOT NULL,
    description character varying,
    meta_info jsonb
);


ALTER TABLE autoservice_schema."order" OWNER TO admin;

--
-- Name: order_car; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.order_car (
    order_id integer NOT NULL,
    car_id character varying(17) NOT NULL
);


ALTER TABLE autoservice_schema.order_car OWNER TO admin;

--
-- Name: order_closure_date; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.order_closure_date (
    order_id integer NOT NULL,
    closure_date timestamp without time zone NOT NULL
);


ALTER TABLE autoservice_schema.order_closure_date OWNER TO admin;

--
-- Name: order_id_seq; Type: SEQUENCE; Schema: autoservice_schema; Owner: admin
--

CREATE SEQUENCE autoservice_schema.order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE autoservice_schema.order_id_seq OWNER TO admin;

--
-- Name: order_id_seq; Type: SEQUENCE OWNED BY; Schema: autoservice_schema; Owner: admin
--

ALTER SEQUENCE autoservice_schema.order_id_seq OWNED BY autoservice_schema."order".id;


--
-- Name: payout; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.payout (
    id integer NOT NULL,
    value integer NOT NULL,
    date timestamp without time zone NOT NULL,
    payout_type character varying NOT NULL,
    worker_id integer NOT NULL
);


ALTER TABLE autoservice_schema.payout OWNER TO admin;

--
-- Name: payout_id_seq; Type: SEQUENCE; Schema: autoservice_schema; Owner: admin
--

CREATE SEQUENCE autoservice_schema.payout_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE autoservice_schema.payout_id_seq OWNER TO admin;

--
-- Name: payout_id_seq; Type: SEQUENCE OWNED BY; Schema: autoservice_schema; Owner: admin
--

ALTER SEQUENCE autoservice_schema.payout_id_seq OWNED BY autoservice_schema.payout.id;


--
-- Name: provider; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.provider (
    id integer NOT NULL,
    address character varying,
    phone_number character varying
);


ALTER TABLE autoservice_schema.provider OWNER TO admin;

--
-- Name: provider_id_seq; Type: SEQUENCE; Schema: autoservice_schema; Owner: admin
--

CREATE SEQUENCE autoservice_schema.provider_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE autoservice_schema.provider_id_seq OWNER TO admin;

--
-- Name: provider_id_seq; Type: SEQUENCE OWNED BY; Schema: autoservice_schema; Owner: admin
--

ALTER SEQUENCE autoservice_schema.provider_id_seq OWNED BY autoservice_schema.provider.id;


--
-- Name: purchase; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.purchase (
    id integer NOT NULL,
    provider_id integer,
    date timestamp without time zone NOT NULL,
    value numeric(19,2),
    discount_period daterange
);


ALTER TABLE autoservice_schema.purchase OWNER TO admin;

--
-- Name: purchase_id_seq; Type: SEQUENCE; Schema: autoservice_schema; Owner: admin
--

CREATE SEQUENCE autoservice_schema.purchase_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE autoservice_schema.purchase_id_seq OWNER TO admin;

--
-- Name: purchase_id_seq; Type: SEQUENCE OWNED BY; Schema: autoservice_schema; Owner: admin
--

ALTER SEQUENCE autoservice_schema.purchase_id_seq OWNED BY autoservice_schema.purchase.id;


--
-- Name: task; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.task (
    id integer NOT NULL,
    order_id integer NOT NULL,
    value numeric(19,2),
    worker_id integer NOT NULL,
    description character varying,
    car_id character varying(17) NOT NULL,
    description_search tsvector,
    CONSTRAINT positive_value CHECK ((value >= (0)::numeric))
);


ALTER TABLE autoservice_schema.task OWNER TO admin;

--
-- Name: task_id_seq; Type: SEQUENCE; Schema: autoservice_schema; Owner: admin
--

CREATE SEQUENCE autoservice_schema.task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE autoservice_schema.task_id_seq OWNER TO admin;

--
-- Name: task_id_seq; Type: SEQUENCE OWNED BY; Schema: autoservice_schema; Owner: admin
--

ALTER SEQUENCE autoservice_schema.task_id_seq OWNED BY autoservice_schema.task.id;


--
-- Name: worker; Type: TABLE; Schema: autoservice_schema; Owner: admin
--

CREATE TABLE autoservice_schema.worker (
    id integer NOT NULL,
    full_name character varying NOT NULL,
    role character varying NOT NULL,
    phone_number character varying NOT NULL,
    id_branch_office integer NOT NULL
);


ALTER TABLE autoservice_schema.worker OWNER TO admin;

--
-- Name: worker_id_seq; Type: SEQUENCE; Schema: autoservice_schema; Owner: admin
--

CREATE SEQUENCE autoservice_schema.worker_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE autoservice_schema.worker_id_seq OWNER TO admin;

--
-- Name: worker_id_seq; Type: SEQUENCE OWNED BY; Schema: autoservice_schema; Owner: admin
--

ALTER SEQUENCE autoservice_schema.worker_id_seq OWNED BY autoservice_schema.worker.id;


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


ALTER TABLE public.flyway_schema_history OWNER TO admin;

--
-- Name: autopart id; Type: DEFAULT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.autopart ALTER COLUMN id SET DEFAULT nextval('autoservice_schema.autopart_id_seq'::regclass);


--
-- Name: box id; Type: DEFAULT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.box ALTER COLUMN id SET DEFAULT nextval('autoservice_schema.box_id_seq'::regclass);


--
-- Name: branch_office id; Type: DEFAULT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.branch_office ALTER COLUMN id SET DEFAULT nextval('autoservice_schema.branch_office_id_seq'::regclass);


--
-- Name: customer id; Type: DEFAULT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.customer ALTER COLUMN id SET DEFAULT nextval('autoservice_schema.customer_id_seq'::regclass);


--
-- Name: order id; Type: DEFAULT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema."order" ALTER COLUMN id SET DEFAULT nextval('autoservice_schema.order_id_seq'::regclass);


--
-- Name: payout id; Type: DEFAULT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.payout ALTER COLUMN id SET DEFAULT nextval('autoservice_schema.payout_id_seq'::regclass);


--
-- Name: provider id; Type: DEFAULT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.provider ALTER COLUMN id SET DEFAULT nextval('autoservice_schema.provider_id_seq'::regclass);


--
-- Name: purchase id; Type: DEFAULT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.purchase ALTER COLUMN id SET DEFAULT nextval('autoservice_schema.purchase_id_seq'::regclass);


--
-- Name: task id; Type: DEFAULT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.task ALTER COLUMN id SET DEFAULT nextval('autoservice_schema.task_id_seq'::regclass);


--
-- Name: worker id; Type: DEFAULT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.worker ALTER COLUMN id SET DEFAULT nextval('autoservice_schema.worker_id_seq'::regclass);


--
-- Name: autopart autopart_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.autopart
    ADD CONSTRAINT autopart_pkey PRIMARY KEY (id);


--
-- Name: autopart autopart_task_id_key; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.autopart
    ADD CONSTRAINT autopart_task_id_key UNIQUE (task_id);


--
-- Name: box box_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.box
    ADD CONSTRAINT box_pkey PRIMARY KEY (id);


--
-- Name: branch_office_manager branch_office_manager_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.branch_office_manager
    ADD CONSTRAINT branch_office_manager_pkey PRIMARY KEY (branch_office_id);


--
-- Name: branch_office branch_office_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.branch_office
    ADD CONSTRAINT branch_office_pkey PRIMARY KEY (id);


--
-- Name: car car_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.car
    ADD CONSTRAINT car_pkey PRIMARY KEY (vin);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- Name: order_car order_car_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.order_car
    ADD CONSTRAINT order_car_pkey PRIMARY KEY (order_id, car_id);


--
-- Name: order_closure_date order_closure_date_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.order_closure_date
    ADD CONSTRAINT order_closure_date_pkey PRIMARY KEY (order_id);


--
-- Name: order order_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema."order"
    ADD CONSTRAINT order_pkey PRIMARY KEY (id);


--
-- Name: payout payout_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.payout
    ADD CONSTRAINT payout_pkey PRIMARY KEY (id);


--
-- Name: provider provider_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.provider
    ADD CONSTRAINT provider_pkey PRIMARY KEY (id);


--
-- Name: purchase purchase_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.purchase
    ADD CONSTRAINT purchase_pkey PRIMARY KEY (id);


--
-- Name: task task_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.task
    ADD CONSTRAINT task_pkey PRIMARY KEY (id);


--
-- Name: worker worker_pkey; Type: CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.worker
    ADD CONSTRAINT worker_pkey PRIMARY KEY (id);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: idx_car_box_id; Type: INDEX; Schema: autoservice_schema; Owner: admin
--

CREATE INDEX idx_car_box_id ON autoservice_schema.car USING btree (box_id);


--
-- Name: idx_car_plate_hash; Type: INDEX; Schema: autoservice_schema; Owner: admin
--

CREATE INDEX idx_car_plate_hash ON autoservice_schema.car USING hash (plate_number);


--
-- Name: idx_car_specs_gin; Type: INDEX; Schema: autoservice_schema; Owner: admin
--

CREATE INDEX idx_car_specs_gin ON autoservice_schema.car USING gin (specs);


--
-- Name: idx_customer_fullname; Type: INDEX; Schema: autoservice_schema; Owner: admin
--

CREATE INDEX idx_customer_fullname ON autoservice_schema.customer USING btree (full_name);


--
-- Name: idx_customer_tags_gin; Type: INDEX; Schema: autoservice_schema; Owner: admin
--

CREATE INDEX idx_customer_tags_gin ON autoservice_schema.customer USING gin (tags);


--
-- Name: idx_payout_worker_value; Type: INDEX; Schema: autoservice_schema; Owner: admin
--

CREATE INDEX idx_payout_worker_value ON autoservice_schema.payout USING btree (worker_id, value);


--
-- Name: idx_purchase_discount_gist; Type: INDEX; Schema: autoservice_schema; Owner: admin
--

CREATE INDEX idx_purchase_discount_gist ON autoservice_schema.purchase USING gist (discount_period);


--
-- Name: idx_task_order_id; Type: INDEX; Schema: autoservice_schema; Owner: admin
--

CREATE INDEX idx_task_order_id ON autoservice_schema.task USING btree (order_id);


--
-- Name: idx_task_tsvector_gist; Type: INDEX; Schema: autoservice_schema; Owner: admin
--

CREATE INDEX idx_task_tsvector_gist ON autoservice_schema.task USING gist (description_search);


--
-- Name: idx_task_value; Type: INDEX; Schema: autoservice_schema; Owner: admin
--

CREATE INDEX idx_task_value ON autoservice_schema.task USING btree (value);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: autopart autopart_purchase_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.autopart
    ADD CONSTRAINT autopart_purchase_id_fkey FOREIGN KEY (purchase_id) REFERENCES autoservice_schema.purchase(id);


--
-- Name: autopart autopart_task_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.autopart
    ADD CONSTRAINT autopart_task_id_fkey FOREIGN KEY (task_id) REFERENCES autoservice_schema.task(id);


--
-- Name: box box_id_branch_office_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.box
    ADD CONSTRAINT box_id_branch_office_fkey FOREIGN KEY (id_branch_office) REFERENCES autoservice_schema.branch_office(id);


--
-- Name: branch_office_manager branch_office_manager_branch_office_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.branch_office_manager
    ADD CONSTRAINT branch_office_manager_branch_office_id_fkey FOREIGN KEY (branch_office_id) REFERENCES autoservice_schema.branch_office(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: branch_office_manager branch_office_manager_manager_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.branch_office_manager
    ADD CONSTRAINT branch_office_manager_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES autoservice_schema.worker(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: car car_box_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.car
    ADD CONSTRAINT car_box_id_fkey FOREIGN KEY (box_id) REFERENCES autoservice_schema.box(id);


--
-- Name: order_car order_car_car_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.order_car
    ADD CONSTRAINT order_car_car_id_fkey FOREIGN KEY (car_id) REFERENCES autoservice_schema.car(vin);


--
-- Name: order_car order_car_order_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.order_car
    ADD CONSTRAINT order_car_order_id_fkey FOREIGN KEY (order_id) REFERENCES autoservice_schema."order"(id);


--
-- Name: order_closure_date order_closure_date_order_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.order_closure_date
    ADD CONSTRAINT order_closure_date_order_id_fkey FOREIGN KEY (order_id) REFERENCES autoservice_schema."order"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: order order_customer_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema."order"
    ADD CONSTRAINT order_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES autoservice_schema.customer(id);


--
-- Name: payout payout_worker_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.payout
    ADD CONSTRAINT payout_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES autoservice_schema.worker(id);


--
-- Name: purchase purchase_provider_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.purchase
    ADD CONSTRAINT purchase_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES autoservice_schema.provider(id);


--
-- Name: task task_car_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.task
    ADD CONSTRAINT task_car_id_fkey FOREIGN KEY (car_id) REFERENCES autoservice_schema.car(vin);


--
-- Name: task task_order_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.task
    ADD CONSTRAINT task_order_id_fkey FOREIGN KEY (order_id) REFERENCES autoservice_schema."order"(id);


--
-- Name: task task_worker_id_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.task
    ADD CONSTRAINT task_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES autoservice_schema.worker(id);


--
-- Name: worker worker_id_branch_office_fkey; Type: FK CONSTRAINT; Schema: autoservice_schema; Owner: admin
--

ALTER TABLE ONLY autoservice_schema.worker
    ADD CONSTRAINT worker_id_branch_office_fkey FOREIGN KEY (id_branch_office) REFERENCES autoservice_schema.branch_office(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO app;
GRANT USAGE ON SCHEMA public TO readonly;


--
-- Name: TABLE flyway_schema_history; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.flyway_schema_history TO app;
GRANT SELECT ON TABLE public.flyway_schema_history TO readonly;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE admin IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES  TO app;
ALTER DEFAULT PRIVILEGES FOR ROLE admin IN SCHEMA public GRANT SELECT ON SEQUENCES  TO readonly;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE admin IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES  TO app;
ALTER DEFAULT PRIVILEGES FOR ROLE admin IN SCHEMA public GRANT SELECT ON TABLES  TO readonly;


--
-- PostgreSQL database dump complete
--

\unrestrict e8WxpaI3trWc3E9TBfeB6mtt4zq3NfMQjXLlkIAOj1Pj6EVlcP4tJ9RLgG5kTr4

