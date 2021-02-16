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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bits_balance_debits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bits_balance_debits (
    id bigint NOT NULL,
    user_id bigint,
    amount integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bits_balance_debits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bits_balance_debits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bits_balance_debits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bits_balance_debits_id_seq OWNED BY public.bits_balance_debits.id;


--
-- Name: bits_balances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bits_balances (
    id bigint NOT NULL,
    balance integer DEFAULT 0,
    user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bits_balances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bits_balances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bits_balances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bits_balances_id_seq OWNED BY public.bits_balances.id;


--
-- Name: bits_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bits_transactions (
    id bigint NOT NULL,
    transaction_id character varying NOT NULL,
    user_id bigint NOT NULL,
    "time" timestamp without time zone NOT NULL,
    purchaser_uid character varying NOT NULL,
    sku character varying NOT NULL,
    amount integer NOT NULL,
    display_name character varying
);


--
-- Name: bits_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bits_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bits_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bits_transactions_id_seq OWNED BY public.bits_transactions.id;


--
-- Name: data_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_migrations (
    version character varying NOT NULL
);


--
-- Name: flipper_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_features (
    id bigint NOT NULL,
    key character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flipper_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_features_id_seq OWNED BY public.flipper_features.id;


--
-- Name: flipper_gates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_gates (
    id bigint NOT NULL,
    feature_key character varying NOT NULL,
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_gates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_gates_id_seq OWNED BY public.flipper_gates.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    transcript_id bigint,
    text text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: stream_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stream_settings (
    id bigint NOT NULL,
    language character varying DEFAULT 'en-US'::character varying,
    user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    hide_text_on_load boolean DEFAULT false,
    text_uppercase boolean DEFAULT false,
    filter_profanity boolean DEFAULT true,
    cc_box_size boolean DEFAULT false,
    switch_settings_position boolean DEFAULT false,
    enable_transcripts boolean DEFAULT false,
    showcase boolean DEFAULT true,
    pirate_mode boolean DEFAULT false,
    caption_delay integer DEFAULT 0
);


--
-- Name: stream_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stream_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stream_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stream_settings_id_seq OWNED BY public.stream_settings.id;


--
-- Name: transcripts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transcripts (
    id bigint NOT NULL,
    user_id bigint,
    name character varying,
    session character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: transcripts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transcripts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transcripts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transcripts_id_seq OWNED BY public.transcripts.id;


--
-- Name: translate_languages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.translate_languages (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    language character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: translate_languages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.translate_languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: translate_languages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.translate_languages_id_seq OWNED BY public.translate_languages.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    last_sign_in_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    provider character varying,
    uid character varying,
    username character varying,
    profile_image_url character varying,
    login character varying,
    description text,
    offline_image_url character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: bits_balance_debits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bits_balance_debits ALTER COLUMN id SET DEFAULT nextval('public.bits_balance_debits_id_seq'::regclass);


--
-- Name: bits_balances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bits_balances ALTER COLUMN id SET DEFAULT nextval('public.bits_balances_id_seq'::regclass);


--
-- Name: bits_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bits_transactions ALTER COLUMN id SET DEFAULT nextval('public.bits_transactions_id_seq'::regclass);


--
-- Name: flipper_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features ALTER COLUMN id SET DEFAULT nextval('public.flipper_features_id_seq'::regclass);


--
-- Name: flipper_gates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates ALTER COLUMN id SET DEFAULT nextval('public.flipper_gates_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: stream_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_settings ALTER COLUMN id SET DEFAULT nextval('public.stream_settings_id_seq'::regclass);


--
-- Name: transcripts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transcripts ALTER COLUMN id SET DEFAULT nextval('public.transcripts_id_seq'::regclass);


--
-- Name: translate_languages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translate_languages ALTER COLUMN id SET DEFAULT nextval('public.translate_languages_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: bits_balance_debits bits_balance_debits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bits_balance_debits
    ADD CONSTRAINT bits_balance_debits_pkey PRIMARY KEY (id);


--
-- Name: bits_balances bits_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bits_balances
    ADD CONSTRAINT bits_balances_pkey PRIMARY KEY (id);


--
-- Name: bits_transactions bits_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bits_transactions
    ADD CONSTRAINT bits_transactions_pkey PRIMARY KEY (id);


--
-- Name: data_migrations data_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_migrations
    ADD CONSTRAINT data_migrations_pkey PRIMARY KEY (version);


--
-- Name: flipper_features flipper_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features
    ADD CONSTRAINT flipper_features_pkey PRIMARY KEY (id);


--
-- Name: flipper_gates flipper_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates
    ADD CONSTRAINT flipper_gates_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: stream_settings stream_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_settings
    ADD CONSTRAINT stream_settings_pkey PRIMARY KEY (id);


--
-- Name: transcripts transcripts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transcripts
    ADD CONSTRAINT transcripts_pkey PRIMARY KEY (id);


--
-- Name: translate_languages translate_languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translate_languages
    ADD CONSTRAINT translate_languages_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_bits_balance_debits_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bits_balance_debits_on_created_at ON public.bits_balance_debits USING btree (created_at);


--
-- Name: index_bits_balance_debits_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bits_balance_debits_on_user_id ON public.bits_balance_debits USING btree (user_id);


--
-- Name: index_bits_balances_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bits_balances_on_user_id ON public.bits_balances USING btree (user_id);


--
-- Name: index_bits_transactions_on_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bits_transactions_on_transaction_id ON public.bits_transactions USING btree (transaction_id);


--
-- Name: index_bits_transactions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bits_transactions_on_user_id ON public.bits_transactions USING btree (user_id);


--
-- Name: index_flipper_features_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_features_on_key ON public.flipper_features USING btree (key);


--
-- Name: index_flipper_gates_on_feature_key_and_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_gates_on_feature_key_and_key_and_value ON public.flipper_gates USING btree (feature_key, key, value);


--
-- Name: index_messages_on_transcript_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_transcript_id ON public.messages USING btree (transcript_id);


--
-- Name: index_stream_settings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stream_settings_on_user_id ON public.stream_settings USING btree (user_id);


--
-- Name: index_transcripts_on_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transcripts_on_session ON public.transcripts USING btree (session);


--
-- Name: index_transcripts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transcripts_on_user_id ON public.transcripts USING btree (user_id);


--
-- Name: index_translate_languages_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_translate_languages_on_user_id ON public.translate_languages USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_uid ON public.users USING btree (uid);


--
-- Name: bits_balances fk_rails_1a2fa97ecf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bits_balances
    ADD CONSTRAINT fk_rails_1a2fa97ecf FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: messages fk_rails_832df11d70; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_832df11d70 FOREIGN KEY (transcript_id) REFERENCES public.transcripts(id);


--
-- Name: stream_settings fk_rails_cd3c3eab8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_settings
    ADD CONSTRAINT fk_rails_cd3c3eab8f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: transcripts fk_rails_d177bec369; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transcripts
    ADD CONSTRAINT fk_rails_d177bec369 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: translate_languages fk_rails_e519515539; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translate_languages
    ADD CONSTRAINT fk_rails_e519515539 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

