--
-- PostgreSQL database dump
--

\restrict tvijLKuJZ9u42XLRcT1bfggU43u2Wulr42cRVbbjjNZZWsyTHLIACIseDAyavdq

-- Dumped from database version 18.0
-- Dumped by pg_dump version 18.0

-- Started on 2026-11-26 09:14:00

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
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
-- TOC entry 220 (class 1259 OID 27302)
-- Name: atendimento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.atendimento (
    id bigint NOT NULL,
    datahora timestamp without time zone NOT NULL,
    statusatendimento character varying(255) NOT NULL,
    tipoatendimento character varying(255) NOT NULL,
    medico_id bigint NOT NULL,
    paciente_id bigint NOT NULL,
    unidade_id bigint NOT NULL
);


ALTER TABLE public.atendimento OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 27301)
-- Name: atendimento_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.atendimento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.atendimento_id_seq OWNER TO postgres;

--
-- TOC entry 5117 (class 0 OID 0)
-- Dependencies: 219
-- Name: atendimento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.atendimento_id_seq OWNED BY public.atendimento.id;


--
-- TOC entry 222 (class 1259 OID 27318)
-- Name: categoria_procedimento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categoria_procedimento (
    id bigint NOT NULL,
    nome character varying(255) NOT NULL
);


ALTER TABLE public.categoria_procedimento OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 27317)
-- Name: categoria_procedimento_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categoria_procedimento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categoria_procedimento_id_seq OWNER TO postgres;

--
-- TOC entry 5118 (class 0 OID 0)
-- Dependencies: 221
-- Name: categoria_procedimento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categoria_procedimento_id_seq OWNED BY public.categoria_procedimento.id;


--
-- TOC entry 224 (class 1259 OID 27327)
-- Name: convenio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.convenio (
    id bigint NOT NULL,
    nome character varying(255) NOT NULL,
    percentual_desconto numeric(5,2)
);


ALTER TABLE public.convenio OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 27326)
-- Name: convenio_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.convenio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.convenio_id_seq OWNER TO postgres;

--
-- TOC entry 5119 (class 0 OID 0)
-- Dependencies: 223
-- Name: convenio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.convenio_id_seq OWNED BY public.convenio.id;


--
-- TOC entry 226 (class 1259 OID 27336)
-- Name: especialidade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.especialidade (
    id bigint NOT NULL,
    nome character varying(255) NOT NULL
);


ALTER TABLE public.especialidade OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 27335)
-- Name: especialidade_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.especialidade_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.especialidade_id_seq OWNER TO postgres;

--
-- TOC entry 5120 (class 0 OID 0)
-- Dependencies: 225
-- Name: especialidade_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.especialidade_id_seq OWNED BY public.especialidade.id;


--
-- TOC entry 228 (class 1259 OID 27345)
-- Name: item_atendimento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_atendimento (
    id bigint NOT NULL,
    desconto numeric(10,2),
    quantidade integer NOT NULL,
    valor_unitario numeric(10,2),
    atendimento_id bigint NOT NULL,
    procedimento_id bigint NOT NULL
);


ALTER TABLE public.item_atendimento OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 27344)
-- Name: item_atendimento_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.item_atendimento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_atendimento_id_seq OWNER TO postgres;

--
-- TOC entry 5121 (class 0 OID 0)
-- Dependencies: 227
-- Name: item_atendimento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_atendimento_id_seq OWNED BY public.item_atendimento.id;


--
-- TOC entry 229 (class 1259 OID 27355)
-- Name: medico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medico (
    crm character varying(255) NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.medico OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 27362)
-- Name: medico_especialidade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medico_especialidade (
    medico_id bigint NOT NULL,
    especialidade_id bigint NOT NULL
);


ALTER TABLE public.medico_especialidade OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 27367)
-- Name: paciente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.paciente (
    data_cadastro date,
    id bigint NOT NULL,
    convenio_id bigint
);


ALTER TABLE public.paciente OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 27374)
-- Name: pessoa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pessoa (
    id bigint NOT NULL,
    cpf character varying(255),
    datanascimento date,
    email character varying(255),
    bairro character varying(255),
    cep character varying(255),
    cidade character varying(255),
    numero character varying(255),
    rua character varying(255),
    uf character varying(255),
    nome character varying(255) NOT NULL,
    telefone character varying(255)
);


ALTER TABLE public.pessoa OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 27373)
-- Name: pessoa_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pessoa_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pessoa_id_seq OWNER TO postgres;

--
-- TOC entry 5122 (class 0 OID 0)
-- Dependencies: 232
-- Name: pessoa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pessoa_id_seq OWNED BY public.pessoa.id;


--
-- TOC entry 235 (class 1259 OID 27385)
-- Name: procedimento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.procedimento (
    id bigint NOT NULL,
    codigo character varying(255) NOT NULL,
    nome character varying(255) NOT NULL,
    valor_base numeric(10,2),
    categoria_id bigint NOT NULL
);


ALTER TABLE public.procedimento OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 27384)
-- Name: procedimento_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.procedimento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.procedimento_id_seq OWNER TO postgres;

--
-- TOC entry 5123 (class 0 OID 0)
-- Dependencies: 234
-- Name: procedimento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.procedimento_id_seq OWNED BY public.procedimento.id;


--
-- TOC entry 237 (class 1259 OID 27398)
-- Name: prontuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prontuario (
    id bigint NOT NULL,
    alergias character varying(1000),
    dataabertura date,
    observacoes character varying(2000),
    tiposanguineo character varying(255),
    paciente_id bigint NOT NULL
);


ALTER TABLE public.prontuario OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 27397)
-- Name: prontuario_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prontuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.prontuario_id_seq OWNER TO postgres;

--
-- TOC entry 5124 (class 0 OID 0)
-- Dependencies: 236
-- Name: prontuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prontuario_id_seq OWNED BY public.prontuario.id;


--
-- TOC entry 239 (class 1259 OID 27409)
-- Name: unidade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.unidade (
    id bigint NOT NULL,
    bairro character varying(255),
    cep character varying(255),
    cidade character varying(255),
    numero character varying(255),
    rua character varying(255),
    uf character varying(255),
    nome character varying(255) NOT NULL,
    telefone character varying(255)
);


ALTER TABLE public.unidade OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 27408)
-- Name: unidade_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.unidade_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.unidade_id_seq OWNER TO postgres;

--
-- TOC entry 5125 (class 0 OID 0)
-- Dependencies: 238
-- Name: unidade_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.unidade_id_seq OWNED BY public.unidade.id;


--
-- TOC entry 4908 (class 2604 OID 27305)
-- Name: atendimento id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atendimento ALTER COLUMN id SET DEFAULT nextval('public.atendimento_id_seq'::regclass);


--
-- TOC entry 4909 (class 2604 OID 27321)
-- Name: categoria_procedimento id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria_procedimento ALTER COLUMN id SET DEFAULT nextval('public.categoria_procedimento_id_seq'::regclass);


--
-- TOC entry 4910 (class 2604 OID 27330)
-- Name: convenio id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.convenio ALTER COLUMN id SET DEFAULT nextval('public.convenio_id_seq'::regclass);


--
-- TOC entry 4911 (class 2604 OID 27339)
-- Name: especialidade id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especialidade ALTER COLUMN id SET DEFAULT nextval('public.especialidade_id_seq'::regclass);


--
-- TOC entry 4912 (class 2604 OID 27348)
-- Name: item_atendimento id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_atendimento ALTER COLUMN id SET DEFAULT nextval('public.item_atendimento_id_seq'::regclass);


--
-- TOC entry 4913 (class 2604 OID 27377)
-- Name: pessoa id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoa ALTER COLUMN id SET DEFAULT nextval('public.pessoa_id_seq'::regclass);


--
-- TOC entry 4914 (class 2604 OID 27388)
-- Name: procedimento id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.procedimento ALTER COLUMN id SET DEFAULT nextval('public.procedimento_id_seq'::regclass);


--
-- TOC entry 4915 (class 2604 OID 27401)
-- Name: prontuario id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prontuario ALTER COLUMN id SET DEFAULT nextval('public.prontuario_id_seq'::regclass);


--
-- TOC entry 4916 (class 2604 OID 27412)
-- Name: unidade id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unidade ALTER COLUMN id SET DEFAULT nextval('public.unidade_id_seq'::regclass);


--
-- TOC entry 4918 (class 2606 OID 27316)
-- Name: atendimento atendimento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atendimento
    ADD CONSTRAINT atendimento_pkey PRIMARY KEY (id);


--
-- TOC entry 4920 (class 2606 OID 27325)
-- Name: categoria_procedimento categoria_procedimento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria_procedimento
    ADD CONSTRAINT categoria_procedimento_pkey PRIMARY KEY (id);


--
-- TOC entry 4924 (class 2606 OID 27334)
-- Name: convenio convenio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.convenio
    ADD CONSTRAINT convenio_pkey PRIMARY KEY (id);


--
-- TOC entry 4926 (class 2606 OID 27343)
-- Name: especialidade especialidade_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especialidade
    ADD CONSTRAINT especialidade_pkey PRIMARY KEY (id);


--
-- TOC entry 4930 (class 2606 OID 27354)
-- Name: item_atendimento item_atendimento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_atendimento
    ADD CONSTRAINT item_atendimento_pkey PRIMARY KEY (id);


--
-- TOC entry 4932 (class 2606 OID 27361)
-- Name: medico medico_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medico
    ADD CONSTRAINT medico_pkey PRIMARY KEY (id);


--
-- TOC entry 4936 (class 2606 OID 27372)
-- Name: paciente paciente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT paciente_pkey PRIMARY KEY (id);


--
-- TOC entry 4940 (class 2606 OID 27383)
-- Name: pessoa pessoa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoa
    ADD CONSTRAINT pessoa_pkey PRIMARY KEY (id);


--
-- TOC entry 4944 (class 2606 OID 27396)
-- Name: procedimento procedimento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.procedimento
    ADD CONSTRAINT procedimento_pkey PRIMARY KEY (id);


--
-- TOC entry 4948 (class 2606 OID 27407)
-- Name: prontuario prontuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prontuario
    ADD CONSTRAINT prontuario_pkey PRIMARY KEY (id);


--
-- TOC entry 4922 (class 2606 OID 27420)
-- Name: categoria_procedimento uk_b0iy90ki3q0a9klg6e47f3u68; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria_procedimento
    ADD CONSTRAINT uk_b0iy90ki3q0a9klg6e47f3u68 UNIQUE (nome);


--
-- TOC entry 4938 (class 2606 OID 27426)
-- Name: paciente uk_dhx1c62nvgc6n1gl5lsuv9gpm; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT uk_dhx1c62nvgc6n1gl5lsuv9gpm UNIQUE (convenio_id);


--
-- TOC entry 4934 (class 2606 OID 27424)
-- Name: medico uk_gchpdsdnxfv1vuayn3tkspvpj; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medico
    ADD CONSTRAINT uk_gchpdsdnxfv1vuayn3tkspvpj UNIQUE (crm);


--
-- TOC entry 4946 (class 2606 OID 27430)
-- Name: procedimento uk_ml8q36ovus9pprxochl55tg1o; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.procedimento
    ADD CONSTRAINT uk_ml8q36ovus9pprxochl55tg1o UNIQUE (codigo);


--
-- TOC entry 4942 (class 2606 OID 27428)
-- Name: pessoa uk_nlwiu48rutiltbnjle59krljo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoa
    ADD CONSTRAINT uk_nlwiu48rutiltbnjle59krljo UNIQUE (cpf);


--
-- TOC entry 4928 (class 2606 OID 27422)
-- Name: especialidade uk_rpkedtjcgmd2qw3euipqv5fhu; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especialidade
    ADD CONSTRAINT uk_rpkedtjcgmd2qw3euipqv5fhu UNIQUE (nome);


--
-- TOC entry 4950 (class 2606 OID 27432)
-- Name: prontuario uk_yc7ck1mrf6wcde5oyiot16ra; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prontuario
    ADD CONSTRAINT uk_yc7ck1mrf6wcde5oyiot16ra UNIQUE (paciente_id);


--
-- TOC entry 4952 (class 2606 OID 27418)
-- Name: unidade unidade_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unidade
    ADD CONSTRAINT unidade_pkey PRIMARY KEY (id);


--
-- TOC entry 4953 (class 2606 OID 27438)
-- Name: atendimento fk5otidx5k8xbj2jv2lp1ie76n6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atendimento
    ADD CONSTRAINT fk5otidx5k8xbj2jv2lp1ie76n6 FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- TOC entry 4954 (class 2606 OID 27443)
-- Name: atendimento fk631pby9mvjkqdqv5jd8umcu8v; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atendimento
    ADD CONSTRAINT fk631pby9mvjkqdqv5jd8umcu8v FOREIGN KEY (unidade_id) REFERENCES public.unidade(id);


--
-- TOC entry 4961 (class 2606 OID 27473)
-- Name: paciente fk6x6ifgovvk7daeq7vbeeclmcv; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT fk6x6ifgovvk7daeq7vbeeclmcv FOREIGN KEY (convenio_id) REFERENCES public.convenio(id);


--
-- TOC entry 4959 (class 2606 OID 27468)
-- Name: medico_especialidade fkbhtjhvqs7ga4awggpvewlvcc4; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medico_especialidade
    ADD CONSTRAINT fkbhtjhvqs7ga4awggpvewlvcc4 FOREIGN KEY (medico_id) REFERENCES public.medico(id);


--
-- TOC entry 4960 (class 2606 OID 27463)
-- Name: medico_especialidade fkbt7xnmc3irfv6h8r9xymm03dp; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medico_especialidade
    ADD CONSTRAINT fkbt7xnmc3irfv6h8r9xymm03dp FOREIGN KEY (especialidade_id) REFERENCES public.especialidade(id);


--
-- TOC entry 4964 (class 2606 OID 27488)
-- Name: prontuario fkfk22x2rbppqhl26p0mxge2rup; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prontuario
    ADD CONSTRAINT fkfk22x2rbppqhl26p0mxge2rup FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- TOC entry 4956 (class 2606 OID 27453)
-- Name: item_atendimento fkjpyvuhul7jtcv6stx153b1wuu; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_atendimento
    ADD CONSTRAINT fkjpyvuhul7jtcv6stx153b1wuu FOREIGN KEY (procedimento_id) REFERENCES public.procedimento(id);


--
-- TOC entry 4957 (class 2606 OID 27448)
-- Name: item_atendimento fkl592x4tfootoa7afe2xbrakv1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_atendimento
    ADD CONSTRAINT fkl592x4tfootoa7afe2xbrakv1 FOREIGN KEY (atendimento_id) REFERENCES public.atendimento(id);


--
-- TOC entry 4955 (class 2606 OID 27433)
-- Name: atendimento fkqlaffnrf4fa98heo2bsbt3q2w; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atendimento
    ADD CONSTRAINT fkqlaffnrf4fa98heo2bsbt3q2w FOREIGN KEY (medico_id) REFERENCES public.medico(id);


--
-- TOC entry 4958 (class 2606 OID 27458)
-- Name: medico fkqnnavtx1jjk4p5becas85ta72; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medico
    ADD CONSTRAINT fkqnnavtx1jjk4p5becas85ta72 FOREIGN KEY (id) REFERENCES public.pessoa(id);


--
-- TOC entry 4963 (class 2606 OID 27483)
-- Name: procedimento fks5exfhsydughpsc63213hj09g; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.procedimento
    ADD CONSTRAINT fks5exfhsydughpsc63213hj09g FOREIGN KEY (categoria_id) REFERENCES public.categoria_procedimento(id);


--
-- TOC entry 4962 (class 2606 OID 27478)
-- Name: paciente fks90bfv7asc6k39qiwilkekb2k; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT fks90bfv7asc6k39qiwilkekb2k FOREIGN KEY (id) REFERENCES public.pessoa(id);


-- Completed on 2026-11-26 09:14:00

--
-- PostgreSQL database dump complete
--

\unrestrict tvijLKuJZ9u42XLRcT1bfggU43u2Wulr42cRVbbjjNZZWsyTHLIACIseDAyavdq

