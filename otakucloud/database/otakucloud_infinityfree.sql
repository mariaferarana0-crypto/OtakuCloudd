-- OtakuCloud v2 para InfinityFree. Importar solo en una base nueva vacia.
SET NAMES utf8mb4;
-- OtakuCloud | MySQL 8 / MariaDB 10.4+ (XAMPP)
-- Importar una sola vez en una base vacia. No elimina datos existentes.


CREATE TABLE usuarios (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(80) NOT NULL,
 correo VARCHAR(190) NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,
 rol ENUM('usuario','admin') NOT NULL DEFAULT 'usuario',
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE obras (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 titulo VARCHAR(180) NOT NULL,
 tipo ENUM('anime','manga','manhwa') NOT NULL,
 autor VARCHAR(120), sinopsis TEXT NOT NULL,
 portada VARCHAR(255),
 estado_publicacion ENUM('en_publicacion','finalizado','pausado') NOT NULL DEFAULT 'en_publicacion',
 destacado BOOLEAN NOT NULL DEFAULT FALSE,
 creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_tipo (tipo), INDEX idx_titulo (titulo)
) ENGINE=InnoDB;
CREATE TABLE generos (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;
CREATE TABLE obra_genero (
 obra_id INT UNSIGNED NOT NULL, genero_id INT UNSIGNED NOT NULL,
 PRIMARY KEY (obra_id,genero_id),
 FOREIGN KEY (obra_id) REFERENCES obras(id) ON DELETE CASCADE,
 FOREIGN KEY (genero_id) REFERENCES generos(id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE capitulos (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 obra_id INT UNSIGNED NOT NULL,
 numero SMALLINT UNSIGNED NOT NULL CHECK (numero > 0),
 titulo VARCHAR(180), fecha_publicacion DATE,
 UNIQUE (obra_id,numero), UNIQUE (obra_id,id),
 FOREIGN KEY (obra_id) REFERENCES obras(id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE biblioteca (
 usuario_id INT UNSIGNED NOT NULL, obra_id INT UNSIGNED NOT NULL,
 estado ENUM('pendiente','en_progreso','completado','en_pausa','abandonado') NOT NULL DEFAULT 'pendiente',
 favorito BOOLEAN NOT NULL DEFAULT FALSE,
 agregado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 PRIMARY KEY (usuario_id,obra_id),
 FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
 FOREIGN KEY (obra_id) REFERENCES obras(id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE progreso_capitulos (
 usuario_id INT UNSIGNED NOT NULL, obra_id INT UNSIGNED NOT NULL, capitulo_id INT UNSIGNED NOT NULL,
 completado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (usuario_id,obra_id,capitulo_id),
 FOREIGN KEY (usuario_id,obra_id) REFERENCES biblioteca(usuario_id,obra_id) ON DELETE CASCADE,
 FOREIGN KEY (obra_id,capitulo_id) REFERENCES capitulos(obra_id,id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE resenas (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 usuario_id INT UNSIGNED NOT NULL, obra_id INT UNSIGNED NOT NULL,
 puntuacion TINYINT UNSIGNED NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
 comentario TEXT, visible BOOLEAN NOT NULL DEFAULT TRUE,
 creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UNIQUE (usuario_id,obra_id),
 FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
 FOREIGN KEY (obra_id) REFERENCES obras(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Datos ficticios; ejecutar una sola vez tras otakucloud.sql.

START TRANSACTION;
INSERT INTO generos(nombre) VALUES ('Accion'),('Romance'),('Fantasia'),('Comedia'),('Drama'),('Aventura'),('Escolar'),('Terror');
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,destacado) VALUES
('Cielos de Papel','manga','Autor ficticio A','Dos estudiantes descubren una amistad a traves del dibujo.','en_publicacion',1),
('El Heroe Reencarnado','manhwa','Autor ficticio B','Un joven despierta en un reino lleno de secretos.','en_publicacion',1),
('Academia Nebula','anime','Estudio ficticio C','Un grupo de estudiantes aprende a navegar entre estrellas.','finalizado',1),
('La Flor del Ultimo Verano','manhwa','Autor ficticio D','Una amistad cambia durante las vacaciones.','en_publicacion',0),
('Torres Infinitas','manga','Autor ficticio E','Exploradores buscan la cima de una torre misteriosa.','en_publicacion',0),
('Cafe de Medianoche','anime','Estudio ficticio F','Una cafeteria abre sus puertas a visitantes inesperados.','finalizado',0);
INSERT INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON (o.titulo='Cielos de Papel' AND g.nombre IN ('Romance','Escolar')) OR (o.titulo='El Heroe Reencarnado' AND g.nombre IN ('Accion','Fantasia')) OR (o.titulo='Academia Nebula' AND g.nombre IN ('Aventura','Fantasia')) OR (o.titulo='La Flor del Ultimo Verano' AND g.nombre IN ('Romance','Drama')) OR (o.titulo='Torres Infinitas' AND g.nombre IN ('Accion','Aventura')) OR (o.titulo='Cafe de Medianoche' AND g.nombre IN ('Comedia','Fantasia'));
INSERT INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT(IF(o.tipo='anime','Episodio ','Capitulo '),n.num) FROM obras o CROSS JOIN (SELECT 1 num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6) n;
COMMIT;
-- No se crean cuentas ni contrasenas de ejemplo. Registrar usuarios desde PHP con password_hash().

-- OtakuCloud v2. Actualización acumulativa e idempotente.
-- Seleccionar la base otakucloud en phpMyAdmin. No borra ni reemplaza registros existentes.
-- Los números de capítulos son una muestra para seguimiento, NO el total oficial de obras reales.
SET NAMES utf8mb4;
START TRANSACTION;
INSERT IGNORE INTO generos(nombre) VALUES ('Accion'),('Romance'),('Fantasia'),('Comedia'),('Drama'),('Aventura'),('Escolar'),('Terror'),('Deportes');
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'Naruto', 'manga', 'Masashi Kishimoto', 'Un joven ninja desea ganarse el reconocimiento de su aldea.', 'finalizado', 'assets/img/real-naruto.svg' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='Naruto' AND tipo='manga');
UPDATE obras SET portada='assets/img/real-naruto.svg' WHERE titulo='Naruto' AND tipo='manga' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Accion', 'Fantasia') WHERE o.titulo='Naruto' AND o.tipo='manga';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20) n WHERE o.titulo='Naruto' AND o.tipo='manga';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'Death Note', 'anime', 'Madhouse', 'Un cuaderno sobrenatural enfrenta a un estudiante con un brillante investigador.', 'finalizado', 'assets/img/real-death-note.svg' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='Death Note' AND tipo='anime');
UPDATE obras SET portada='assets/img/real-death-note.svg' WHERE titulo='Death Note' AND tipo='anime' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Drama', 'Terror') WHERE o.titulo='Death Note' AND o.tipo='anime';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Episodio ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20) n WHERE o.titulo='Death Note' AND o.tipo='anime';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'Solo Leveling', 'manhwa', 'Chugong; DUBU', 'Un cazador de bajo rango obtiene una oportunidad para desarrollar poderes extraordinarios.', 'finalizado', 'assets/img/real-solo-leveling.svg' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='Solo Leveling' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/real-solo-leveling.svg' WHERE titulo='Solo Leveling' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Accion', 'Fantasia') WHERE o.titulo='Solo Leveling' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30) n WHERE o.titulo='Solo Leveling' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'Omniscient Reader', 'manhwa', 'singNsong; UMI; Sleepy-C', 'Un lector reconoce las reglas de una novela apocalíptica cuando estas se convierten en realidad.', 'en_publicacion', 'assets/img/real-omniscient-reader.svg' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='Omniscient Reader' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/real-omniscient-reader.svg' WHERE titulo='Omniscient Reader' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Accion', 'Fantasia') WHERE o.titulo='Omniscient Reader' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30) n WHERE o.titulo='Omniscient Reader' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'The World After the Fall', 'manhwa', 'singNsong; Undead Ttalgi; Undead Gamja', 'Un guerrero se niega a abandonar su realidad y descubre los misterios de las torres.', 'en_publicacion', 'assets/img/real-world-after-fall.svg' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='The World After the Fall' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/real-world-after-fall.svg' WHERE titulo='The World After the Fall' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Accion', 'Fantasia', 'Aventura') WHERE o.titulo='The World After the Fall' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30) n WHERE o.titulo='The World After the Fall' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'The Remarried Empress', 'manhwa', 'Alphatart; HereLee; SUMPUL', 'Una emperatriz afronta una crisis matrimonial y toma las riendas de su destino político.', 'finalizado', 'assets/img/real-remarried-empress.svg' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='The Remarried Empress' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/real-remarried-empress.svg' WHERE titulo='The Remarried Empress' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Romance', 'Fantasia', 'Drama') WHERE o.titulo='The Remarried Empress' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30) n WHERE o.titulo='The Remarried Empress' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'The Greatest Estate Developer', 'manhwa', 'BK_Moon; Lee Hyunmin; Kim Hyunsoo', 'Un estudiante de ingeniería despierta en un mundo fantástico y emplea sus conocimientos para rescatar una propiedad endeudada.', 'finalizado', 'assets/img/real-greatest-estate.svg' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='The Greatest Estate Developer' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/real-greatest-estate.svg' WHERE titulo='The Greatest Estate Developer' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Comedia', 'Fantasia', 'Aventura') WHERE o.titulo='The Greatest Estate Developer' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30) n WHERE o.titulo='The Greatest Estate Developer' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'Eleceed', 'manhwa', 'Jeho Son; ZHENA', 'Un joven con reflejos sobrenaturales conoce a un fugitivo que se ha transformado en gato.', 'en_publicacion', 'assets/img/real-eleceed.svg' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='Eleceed' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/real-eleceed.svg' WHERE titulo='Eleceed' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Accion', 'Fantasia', 'Comedia') WHERE o.titulo='Eleceed' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30) n WHERE o.titulo='Eleceed' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'Tower of God', 'manhwa', 'SIU', 'Un joven se adentra en una torre en la que cada nivel plantea nuevas pruebas y alianzas.', 'pausado', 'assets/img/real-tower-of-god.svg' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='Tower of God' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/real-tower-of-god.svg' WHERE titulo='Tower of God' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Accion', 'Fantasia', 'Aventura') WHERE o.titulo='Tower of God' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30) n WHERE o.titulo='Tower of God' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'The Boxer', 'manhwa', 'JH', 'Un boxeador excepcional busca su lugar en un deporte que pone a prueba el cuerpo y el carácter.', 'finalizado', 'assets/img/real-the-boxer.svg' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='The Boxer' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/real-the-boxer.svg' WHERE titulo='The Boxer' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Drama', 'Deportes') WHERE o.titulo='The Boxer' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30) n WHERE o.titulo='The Boxer' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'Marry My Husband', 'manhwa', 'Sungsojak; LICO', 'Una mujer recibe una segunda oportunidad para cambiar el rumbo de su vida tras una traición.', 'finalizado', 'assets/img/real-marry-my-husband.svg' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='Marry My Husband' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/real-marry-my-husband.svg' WHERE titulo='Marry My Husband' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Romance', 'Drama', 'Fantasia') WHERE o.titulo='Marry My Husband' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30) n WHERE o.titulo='Marry My Husband' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'Corona de Esmeralda', 'manhwa', 'OtakuCloud Originals', 'Una heredera de un reino oculto debe descubrir quién amenaza el bosque encantado.', 'en_publicacion', 'assets/img/corona.webp' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='Corona de Esmeralda' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/corona.webp' WHERE titulo='Corona de Esmeralda' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Romance', 'Fantasia') WHERE o.titulo='Corona de Esmeralda' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18) n WHERE o.titulo='Corona de Esmeralda' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'El Príncipe de la Luna', 'manhwa', 'OtakuCloud Originals', 'Un príncipe de las tierras del norte esconde un pacto que cambiará el destino de dos reinos.', 'en_publicacion', 'assets/img/luna.webp' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='El Príncipe de la Luna' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/luna.webp' WHERE titulo='El Príncipe de la Luna' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Fantasia', 'Romance') WHERE o.titulo='El Príncipe de la Luna' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16) n WHERE o.titulo='El Príncipe de la Luna' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'Juramento Carmesí', 'manhwa', 'OtakuCloud Originals', 'Un caballero exiliado regresa para cumplir una promesa que hizo bajo un cielo de fuego.', 'en_publicacion', 'assets/img/juramento.webp' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='Juramento Carmesí' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/juramento.webp' WHERE titulo='Juramento Carmesí' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Accion', 'Aventura') WHERE o.titulo='Juramento Carmesí' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20) n WHERE o.titulo='Juramento Carmesí' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'La Biblioteca de los Astros', 'manhwa', 'OtakuCloud Originals', 'Una aprendiz de magia descubre una biblioteca que guarda los recuerdos de estrellas desaparecidas.', 'en_publicacion', 'assets/img/biblioteca.webp' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='La Biblioteca de los Astros' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/biblioteca.webp' WHERE titulo='La Biblioteca de los Astros' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Fantasia', 'Aventura') WHERE o.titulo='La Biblioteca de los Astros' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12) n WHERE o.titulo='La Biblioteca de los Astros' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'La Espada del Viento', 'manhwa', 'OtakuCloud Originals', 'Un joven espadachín recorre montañas sagradas para resolver el misterio de su clan.', 'finalizado', 'assets/img/espada.webp' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='La Espada del Viento' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/espada.webp' WHERE titulo='La Espada del Viento' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Accion', 'Aventura') WHERE o.titulo='La Espada del Viento' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24) n WHERE o.titulo='La Espada del Viento' AND o.tipo='manhwa';
INSERT INTO obras(titulo,tipo,autor,sinopsis,estado_publicacion,portada) SELECT 'Mi Compañero es un Dragón', 'manhwa', 'OtakuCloud Originals', 'Un explorador torpe se hace amigo de un pequeño dragón que lo acompaña a través de ciudades flotantes.', 'en_publicacion', 'assets/img/dragon.webp' WHERE NOT EXISTS(SELECT 1 FROM obras WHERE titulo='Mi Compañero es un Dragón' AND tipo='manhwa');
UPDATE obras SET portada='assets/img/dragon.webp' WHERE titulo='Mi Compañero es un Dragón' AND tipo='manhwa' AND (portada IS NULL OR portada='' OR portada='assets/img/placeholder.svg');
INSERT IGNORE INTO obra_genero(obra_id,genero_id) SELECT o.id,g.id FROM obras o JOIN generos g ON g.nombre IN ('Comedia', 'Fantasia', 'Aventura') WHERE o.titulo='Mi Compañero es un Dragón' AND o.tipo='manhwa';
INSERT IGNORE INTO capitulos(obra_id,numero,titulo) SELECT o.id,n.num,CONCAT('Capítulo ',n.num) FROM obras o CROSS JOIN (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15) n WHERE o.titulo='Mi Compañero es un Dragón' AND o.tipo='manhwa';
COMMIT;
