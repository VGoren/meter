/*Cправочники*/
DROP TABLE IF EXISTS meter.utility_type        CASCADE; -- Типы коммунальных услуг
DROP TABLE IF EXISTS meter.device_type         CASCADE; -- Типы приборов
DROP TABLE IF EXISTS meter.device_utility_type CASCADE; -- Связочная device_type-utility_type(many to many)
DROP TABLE IF EXISTS meter.manufacturer        CASCADE; -- Производители приборов
DROP TABLE IF EXISTS meter.location_type       CASCADE; -- Типы адресов
DROP TABLE IF EXISTS meter.model               CASCADE; -- Модели приборов

DROP TABLE IF EXISTS meter.location            CASCADE; -- Адреса
DROP TABLE IF EXISTS meter.meter               CASCADE; -- Приборы
DROP TABLE IF EXISTS meter.meter_installation  CASCADE; -- Установки счетчиков по адресам
														-- да, 1 и тот же счетчик может быть привязан одновременно 
														-- к одной и той же локации в активном статусе
														-- это нелогично - здесь потребуется сложный триггер с бизнес-логикой - это не в ТЗ.
														-- К этой таблице в будущем можно будет прукручивать все финансовые таблицы
														-- (лицевые счета, оплаты, тарифы)
DROP TABLE IF EXISTS meter.reading             CASCADE; -- Чтение показателей

DROP SCHEMA IF EXISTS meter CASCADE;
CREATE SCHEMA meter;

CREATE TABLE meter.utility_type (
    id              SERIAL,
    name            VARCHAR(100) NOT NULL,
    CONSTRAINT pk_utility_type         PRIMARY KEY (id),
    CONSTRAINT uq_utility_type_name    UNIQUE      (name)
);
CREATE TABLE meter.device_type (
    id              SERIAL,
    name            VARCHAR(100) NOT NULL,
    CONSTRAINT pk_device_type          PRIMARY KEY (id),
    CONSTRAINT uq_device_type_name     UNIQUE      (name)
);
CREATE TABLE meter.device_utility_type (
    device_type_id  INT          NOT NULL,
    utility_type_id INT          NOT NULL,
    CONSTRAINT pk_device_utility_type  PRIMARY KEY (device_type_id,
                                                    utility_type_id),
    CONSTRAINT fk_device_type_id       FOREIGN KEY (device_type_id)  REFERENCES meter.device_type(id),
    CONSTRAINT fk_utility_type_id      FOREIGN KEY (utility_type_id) REFERENCES meter.utility_type(id)
);
CREATE TABLE meter.manufacturer (
    id              SERIAL,
    name            VARCHAR(100) NOT NULL,
    CONSTRAINT pk_manufacturer         PRIMARY KEY (id),
    CONSTRAINT uq_manufacturer_name    UNIQUE      (name)
);

CREATE TABLE meter.location_type (
    id              SERIAL,
    name            VARCHAR(50)  NOT NULL,
    CONSTRAINT pk_location_type        PRIMARY KEY (id),
    CONSTRAINT uq_location_type_name   UNIQUE      (name)
);
CREATE TABLE meter.model (
    id              SERIAL,
    device_type_id  INT          NOT NULL,
    manufacturer_id INT          NOT NULL,
    model_name      VARCHAR(100) NOT NULL,
    CONSTRAINT pk_model          PRIMARY KEY (id,
                                                   device_type_id), -- Вынуждены для проброса валидации до meter_installation
                                                                    -- (чтобы не могли привязать счетчик хол.воды на горячее водоснабжение)
                                                                    -- Таблица маленькая - это дёшево
    CONSTRAINT fk_models_category     FOREIGN KEY (device_type_id)  REFERENCES meter.device_type(id),
    CONSTRAINT fk_models_manufacturer FOREIGN KEY (manufacturer_id) REFERENCES meter.manufacturer(id)
);

INSERT INTO meter.utility_type  (name) VALUES ('Холодное водоснабжение'), ('Горячее водоснабжение'), ('Газоснабжение'), ('Электроснабжение');
INSERT INTO meter.device_type   (name) VALUES ('Счетчик хол. воды'), ('Счетчик гор. воды'), ('Счетчик хол./гор. воды'), ('Счетчик газовый'), ('Счетчик электрический');

WITH d AS (SELECT * FROM meter.device_type), u AS (SELECT * FROM meter.utility_type)
INSERT INTO meter.device_utility_type (device_type_id, utility_type_id)
          SELECT d.id, u.id FROM d, u WHERE d.name = 'Счетчик хол. воды'      AND u.name = 'Холодное водоснабжение'
UNION ALL SELECT d.id, u.id FROM d, u WHERE d.name = 'Счетчик гор. воды'      AND u.name = 'Горячее водоснабжение'
UNION ALL SELECT d.id, u.id FROM d, u WHERE d.name = 'Счетчик хол./гор. воды' AND u.name = 'Холодное водоснабжение'
UNION ALL SELECT d.id, u.id FROM d, u WHERE d.name = 'Счетчик хол./гор. воды' AND u.name = 'Горячее водоснабжение'
UNION ALL SELECT d.id, u.id FROM d, u WHERE d.name = 'Счетчик газовый'        AND u.name = 'Газоснабжение'
UNION ALL SELECT d.id, u.id FROM d, u WHERE d.name = 'Счетчик электрический'  AND u.name = 'Электроснабжение';

INSERT INTO meter.location_type (name) VALUES ('Квартира'), ('Частный дом'), ('Общедомовое место (ОДН)');
INSERT INTO meter.manufacturer  (name) VALUES ('БелОМО'), ('Гранд'), ('IEK'), ('TDM'), ('ЭКО'),('Эрготех');

WITH m AS (SELECT * FROM meter.manufacturer), d AS (SELECT * FROM meter.device_type)
INSERT INTO meter.model (manufacturer_id, device_type_id, model_name)
          SELECT m.id, d.id, 'СГВ-15 (БелОМО)'          FROM m, d WHERE m.name = 'БелОМО'  AND d.name = 'Счетчик хол./гор. воды'
UNION ALL SELECT m.id, d.id, 'СХВ-15 (БелОМО)'          FROM m, d WHERE m.name = 'БелОМО'  AND d.name = 'Счетчик хол./гор. воды'
UNION ALL SELECT m.id, d.id, 'Берестье Г1.6'            FROM m, d WHERE m.name = 'БелОМО'  AND d.name = 'Счетчик газовый'
UNION ALL SELECT m.id, d.id, 'Гранд 1.6'                FROM m, d WHERE m.name = 'Гранд'   AND d.name = 'Счетчик газовый'
UNION ALL SELECT m.id, d.id, 'Гранд 2.4'                FROM m, d WHERE m.name = 'Гранд'   AND d.name = 'Счетчик газовый'
UNION ALL SELECT m.id, d.id, 'Гранд 3.2'                FROM m, d WHERE m.name = 'Гранд'   AND d.name = 'Счетчик газовый'
UNION ALL SELECT m.id, d.id, 'Гранд 4.0'                FROM m, d WHERE m.name = 'Гранд'   AND d.name = 'Счетчик газовый'
UNION ALL SELECT m.id, d.id, 'Гранд 6.0'                FROM m, d WHERE m.name = 'Гранд'   AND d.name = 'Счетчик газовый'
UNION ALL SELECT m.id, d.id, 'STAR 101/1'               FROM m, d WHERE m.name = 'IEK'     AND d.name = 'Счетчик электрический'
UNION ALL SELECT m.id, d.id, 'STAR 104'                 FROM m, d WHERE m.name = 'IEK'     AND d.name = 'Счетчик электрический'
UNION ALL SELECT m.id, d.id, 'STAR 301 (трехфазный)'    FROM m, d WHERE m.name = 'IEK'     AND d.name = 'Счетчик электрический'
UNION ALL SELECT m.id, d.id, 'STAR 303'                 FROM m, d WHERE m.name = 'IEK'     AND d.name = 'Счетчик электрический'
UNION ALL SELECT m.id, d.id, 'Марс СЕ-1'                FROM m, d WHERE m.name = 'TDM'     AND d.name = 'Счетчик электрический'
UNION ALL SELECT m.id, d.id, 'Марс СЕ-3 (3х тарифный)'  FROM m, d WHERE m.name = 'TDM'     AND d.name = 'Счетчик электрический'
UNION ALL SELECT m.id, d.id, 'Вектор-1'                 FROM m, d WHERE m.name = 'TDM'     AND d.name = 'Счетчик электрический'
UNION ALL SELECT m.id, d.id, 'ЭКО НОМ 15-80'            FROM m, d WHERE m.name = 'ЭКО'     AND d.name = 'Счетчик хол./гор. воды'
UNION ALL SELECT m.id, d.id, 'ЭКО НОМ 15-110 (импульс)' FROM m, d WHERE m.name = 'ЭКО'     AND d.name = 'Счетчик хол./гор. воды'
UNION ALL SELECT m.id, d.id, 'ЭКО НОМ 20-130'           FROM m, d WHERE m.name = 'ЭКО'     AND d.name = 'Счетчик хол./гор. воды'
UNION ALL SELECT m.id, d.id, 'ТК-102'                   FROM m, d WHERE m.name = 'Эрготех' AND d.name = 'Счетчик электрический'
UNION ALL SELECT m.id, d.id, 'ТК-302'                   FROM m, d WHERE m.name = 'Эрготех' AND d.name = 'Счетчик электрический';

/*Экземпляры сущностей*/
CREATE TABLE meter.meter (
    id              SERIAL,
    model_id        INT           NOT NULL,
    device_type_id  INT           NOT NULL,
    serial_number   VARCHAR(50)   NOT NULL,
    manufactured_at DATE,
    CONSTRAINT pk_meter                PRIMARY KEY (id, device_type_id), -- Вынуждены для проброса валидации до meter_installation
                                                                         -- Таблица большая, кол-во строк meter > meter_installation/location
                                                                         -- Это дорого, но всё еще лучше триггера,
                                                                         -- который на каждую вставку в meter_installation будет запускать PL/pgSQL
    CONSTRAINT uq_meter_serial         UNIQUE      (serial_number),
    CONSTRAINT fk_model                FOREIGN KEY (model_id,
                                                    device_type_id)      REFERENCES meter.model(id, device_type_id)
);
CREATE TABLE meter.location (
    id              SERIAL,
    type_id         INT           NOT NULL,
    address         TEXT          NOT NULL,
    CONSTRAINT pk_location             PRIMARY KEY (id),
    CONSTRAINT fk_location_type        FOREIGN KEY (type_id)             REFERENCES meter.location_type(id)
);
CREATE TABLE meter.meter_installation (
    id              SERIAL,
    location_id     INT           NOT NULL,
    meter_id        INT           NOT NULL,
    device_type_id  INT           NOT NULL,
    utility_type_id INT           NOT NULL,
    initial_value   NUMERIC(12,3) NOT NULL DEFAULT 0,
    installed_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    removed_at      TIMESTAMP,
    CONSTRAINT pk_meter_installation   PRIMARY KEY (id),
    CONSTRAINT fk_inst_location        FOREIGN KEY (location_id)         REFERENCES meter.location(id),
    CONSTRAINT fk_inst_meter_valid     FOREIGN KEY (meter_id,
                                                    device_type_id)      REFERENCES meter.meter(id, device_type_id),                           -- Валидация
    CONSTRAINT fk_inst_utility_valid   FOREIGN KEY (device_type_id,
                                                    utility_type_id)     REFERENCES meter.device_utility_type(device_type_id, utility_type_id) -- Валидация
);
CREATE TABLE meter.reading (
    installation_id INT           NOT NULL,
    read_at         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    value           NUMERIC(12,3) NOT NULL,
    CONSTRAINT pk_reading             PRIMARY KEY (installation_id, read_at), -- 2 чтения в одну и ту же наносекунду? BIGSERIAL в принципе не нужен
                                                                              -- дата для поддержки партиционирования
    CONSTRAINT fk_reading_inst        FOREIGN KEY (installation_id)     REFERENCES meter.meter_installation(id)
) PARTITION BY RANGE (read_at);
CREATE TABLE meter.reading_default PARTITION OF meter.reading DEFAULT;
CREATE TABLE meter.reading_2026_q1 PARTITION OF meter.reading FOR VALUES FROM ('2026-01-01') TO ('2026-04-01');
CREATE TABLE meter.reading_2026_q2 PARTITION OF meter.reading FOR VALUES FROM ('2026-04-01') TO ('2026-07-01');
CREATE TABLE meter.reading_2026_q3 PARTITION OF meter.reading FOR VALUES FROM ('2026-07-01') TO ('2026-10-01');
CREATE TABLE meter.reading_2026_q4 PARTITION OF meter.reading FOR VALUES FROM ('2026-10-01') TO ('2027-01-01');


INSERT INTO meter.meter (model_id, device_type_id, serial_number, manufactured_at)
SELECT mm.id,
       mm.device_type_id,
       'SN-' || UPPER(REPLACE(mm.model_name, ' ', '')) || '-' || LPAD(s.id::TEXT, 5, '0'), -- 'SN-Модель-ID'
       CURRENT_DATE - (random() * 1000)::INT * INTERVAL '1 day'
FROM       meter.model               AS mm
CROSS JOIN generate_series(1, 11000) AS s(id);



-- Для генерации использовал ИИ, признаюсь
INSERT INTO meter.location (type_id, address)
SELECT
    CASE
        WHEN i % 20 = 0 THEN (SELECT id FROM meter.location_type WHERE name = 'Общедомовое место (ОДН)')
        WHEN i % 10 = 0 THEN (SELECT id FROM meter.location_type WHERE name = 'Частный дом')
                        ELSE (SELECT id FROM meter.location_type WHERE name = 'Квартира')
    END AS t_id,
    'г. Минск, '
    || (ARRAY['пр. Независимости',
              'ул. Притыцкого',
              'пр. Победителей',
              'ул. Сурганова',
              'ул. Немига',
              'ул. Маяковского',
              'ул. Ленина',
              'пр. Рокоссовского',
              'ул. Якуба Коласа',
              'ул. Филимонова',
              'ул. Казинца',
              'ул. Гамарника',
              'ул. Логойский тракт',
              'ул. Ангарская',
              'ул. Одинцова'])[floor(random()*15)+1]
    || ', д. ' || (floor(random()*150) + 1)::text ||
    CASE
        WHEN i % 20  = 0 THEN ' ('     || (ARRAY['щитовая', 'ИТП', 'подвал', 'лифтовая'])[floor(random()*4)+1] || ')'
        WHEN i % 10 != 0 THEN ', кв. ' || (floor(random()*250) + 1)::text
                         ELSE ''
    END
FROM generate_series(1, 10000) AS i;

INSERT INTO meter.meter_installation (
    location_id,
    meter_id,
    device_type_id,
    utility_type_id,
    initial_value,
    installed_at,
    removed_at
)
WITH raw_data AS (
    -- Собираем пары адрес-счетчик
    SELECT
        l.id AS l_id,
        m.id AS m_id,
        m.device_type_id AS dt_id,
        (SELECT utility_type_id FROM meter.device_utility_type WHERE device_type_id = m.device_type_id LIMIT 1) AS ut_id,
        (random()*5)::numeric(12,3) AS init_val,
        -- Генерируем случайную дату установки в течение года
        '2026-01-01'::timestamp + (random() * (INTERVAL '315 days')) AS inst_at --365-50 = 315
    FROM meter.location l
    CROSS JOIN LATERAL (
        -- Берем по 2 счетчика на каждую локацию
        SELECT id, device_type_id
        FROM meter.meter
        WHERE id BETWEEN l.id AND l.id + 50
        LIMIT 2
    ) m
),
sequenced_data AS (
    -- Определяем очередность и "закрываем" предыдущий счетчик датой установки следующего
    SELECT
        *,
        -- LEAD посмотрит на следующую дату установки (inst_at) для этой же локации и этой же услуги
        LEAD(inst_at) OVER (PARTITION BY l_id, ut_id ORDER BY inst_at) AS next_inst_at
    FROM raw_data
)
SELECT
    l_id,
    m_id,
    dt_id,
    ut_id,
    init_val,
    inst_at,
    next_inst_at -- это и будет датой снятия старого прибора (removed_at)
FROM sequenced_data;

ALTER TABLE meter.reading DROP CONSTRAINT IF EXISTS pk_reading;
INSERT INTO meter.reading (installation_id, read_at, value)
SELECT
    installation_id,
    dt,
    initial_value + SUM(daily_consumption) OVER (PARTITION BY installation_id ORDER BY dt)
FROM (
    SELECT
        i.id AS installation_id,
        i.initial_value,
        s.dt,
        (0.1 + random() * 0.3)::numeric(12,3) AS daily_consumption -- Генерируем случайный расход за ОДИН день (от 0.1 до 0.4 единиц)
    FROM meter.meter_installation i
    CROSS JOIN LATERAL generate_series(
        i.installed_at,
        i.installed_at + INTERVAL '50 days', -- интервал измерений
        INTERVAL '1 day'
    ) AS s(dt)
) sub;
ALTER TABLE meter.reading ADD CONSTRAINT pk_reading PRIMARY KEY (installation_id, read_at);
-- дальше без ИИ



--SELECT * FROM meter.location;
--SELECT * FROM meter.meter;
--SELECT * FROM meter.reading;





/*
-- Фнункция отчета по локации за месяц
-- Поиск примеров с заменой счетчиков
SELECT f.location_id,
       f.serial_number,
       f.utility_name,
       f.val_start,
       f.val_end,
       f.consumption,
       mi.installed_at,
       mi.removed_at,
       CASE WHEN mi.removed_at IS NOT NULL THEN 'Закрыт' ELSE 'Активен' END AS status,
       f.address
FROM meter.get_report(NULL, '2026-02-01') f
JOIN meter.meter                          m  ON f.serial_number = m.serial_number
JOIN meter.meter_installation             mi ON m.id            = mi.meter_id
                                            AND f.location_id   = mi.location_id
WHERE f.location_id IN (
    SELECT location_id FROM meter.get_report(NULL, '2026-02-01') GROUP BY location_id, utility_name
    HAVING COUNT(*) > 1
)
ORDER BY f.location_id DESC, f.utility_name, mi.installed_at;

SELECT serial_number, utility_name, val_start, val_end, consumption, initial_value, address
FROM meter.get_report(9909, '2026-02-01');
*/
CREATE OR REPLACE FUNCTION meter.get_report(p_location_id INT, p_report_date DATE)
RETURNS TABLE (
    -- Дебаг поля, это не inline функция, оптимизатор по ним отработает, так что в бою нужно будет закомментить
    location_id      INT,      --
    date_min         TIMESTAMP,--
    date_max         TIMESTAMP,--
    -- Рабочие поля
    serial_number    VARCHAR,
    device_type_name VARCHAR,
    utility_name     VARCHAR,
    val_start        NUMERIC,
    val_end          NUMERIC,
    consumption      NUMERIC,
    initial_value    NUMERIC,
    address          TEXT
) AS $$
DECLARE
    v_start TIMESTAMP := date_trunc('month', p_report_date);
    v_end   TIMESTAMP := v_start + INTERVAL '1 month';
BEGIN
    RETURN QUERY
    WITH reading AS (
        SELECT
            installation_id                                 AS installation_id,
            MIN(value)   OVER(PARTITION BY installation_id) AS v_min,
            MAX(value)   OVER(PARTITION BY installation_id) AS v_max,
            MIN(read_at) OVER(PARTITION BY installation_id) AS d_min,
            MAX(read_at) OVER(PARTITION BY installation_id) AS d_max
        FROM meter.reading
        WHERE read_at >= v_start
          AND read_at <  v_end
    )
    SELECT DISTINCT
       meter_installation.location_id             AS location_id, --
       d_min                                      AS date_min,    --
       d_max                                      AS date_max,    --

       meter.serial_number::VARCHAR               AS serial_number,
       device_type.name   ::VARCHAR               AS device_type_name,
       utility_type.name  ::VARCHAR               AS utility_name,
       CASE
           WHEN installed_at >= v_start                                                              -- Если поставили прибор в отчетном месяце
           THEN meter_installation.initial_value                                                     -- берем начальное значение
           ELSE v_min
       END                                        AS val_start,
       reading.v_max                              AS val_end,
       CASE
           WHEN installed_at >= v_start                                                              -- Если поставили прибор в отчетном месяце
           THEN COALESCE(v_max, meter_installation.initial_value) - meter_installation.initial_value -- отнимаем от начального
           ELSE COALESCE(v_max - v_min, 0)
       END                                        AS consumption,
       meter_installation.initial_value           AS initial_value,
       location.address                           AS address
    FROM       meter.meter_installation AS meter_installation
    INNER JOIN meter.meter              AS meter              ON meter_installation.meter_id        = meter.id
    INNER JOIN meter.device_type        AS device_type        ON meter.device_type_id               = device_type.id
    INNER JOIN meter.utility_type       AS utility_type       ON meter_installation.utility_type_id = utility_type.id
    INNER JOIN meter.location           AS location           ON meter_installation.location_id     = location.id
    LEFT  JOIN reading                  AS reading            ON meter_installation.id              = reading.installation_id
    WHERE (meter_installation.location_id  = p_location_id OR p_location_id IS NULL)
      AND meter_installation.installed_at < v_end
      AND (   meter_installation.removed_at IS NULL
           OR meter_installation.removed_at >= v_start);
END;
$$ LANGUAGE plpgsql;
