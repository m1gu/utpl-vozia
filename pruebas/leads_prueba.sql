-- Limpiar datos de prueba anteriores
DELETE FROM public.utpl_llamadas WHERE id_llamada LIKE 'sim-%';
DELETE FROM public.utpl_crm WHERE id_negocio LIKE 'SIM-%';
DELETE FROM public.utpl_registros WHERE id_negocio LIKE 'SIM-%';

INSERT INTO public.utpl_registros (id_negocio, id_interno_negocio, cedula, nombre, apellido, modalidad, producto, telefono1, telefono2, telefono3, telefono4, telefono5, telefono6, intentos_llamada, win_tries, win_stamp, estado_flujo, fecha_reagenda, telefono_index, fecha_ultima_llamada, updated_at) VALUES
  ('SIM-0001', 'INT-0001', '1700000001', 'Juan', 'Perez', 'MODALIDAD EN LINEA', 'FINANZAS', '0999999001', '0999999002', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.851Z'),
  ('SIM-0002', 'INT-0002', '1700000002', 'Maria', 'Gomez', 'POSGRADO', 'DERECHO PENAL', '0999999004', '0999999005', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0003', 'INT-0003', '1700000003', 'Carlos', 'Lopez', 'TECNOLÓGICO', 'CREACION AUDIOVISUAL DIGITAL', '0999999008', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0004', 'INT-0004', '1700000004', 'Ana', 'Rodriguez', 'MODALIDAD EN LINEA', 'CONTABILIDAD Y AUDITORIA', '0999999011', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0005', 'INT-0005', '1700000005', 'Pedro', 'Martinez', 'POSGRADO', 'GESTION FINANCIERA', '0999999014', '0999999015', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0006', 'INT-0006', '1700000006', 'Laura', 'Sanchez', 'TECNOLÓGICO', 'MODELADO BIM', '0999999017', '0999999018', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0007', 'INT-0007', '1700000007', 'Luis', 'Torres', 'MODALIDAD EN LINEA', 'DERECHO', '0999999020', '0999999021', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0008', 'INT-0008', '1700000008', 'Sofia', 'Ramirez', 'POSGRADO', 'DERECHO PENAL', '0999999024', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0009', 'INT-0009', '1700000009', 'Diego', 'Flores', 'TECNOLÓGICO', 'MODELADO BIM', '0999999026', '0999999027', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0010', 'INT-0010', '1700000010', 'Elena', 'Vargas', 'MODALIDAD EN LINEA', 'EDUCACION BASICA', '0999999029', '0999999030', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z')
ON CONFLICT (id_negocio) DO UPDATE SET
  id_interno_negocio = EXCLUDED.id_interno_negocio,
  intentos_llamada = EXCLUDED.intentos_llamada,
  win_tries = EXCLUDED.win_tries,
  win_stamp = EXCLUDED.win_stamp,
  estado_flujo = EXCLUDED.estado_flujo,
  fecha_reagenda = EXCLUDED.fecha_reagenda,
  telefono_index = EXCLUDED.telefono_index,
  fecha_ultima_llamada = EXCLUDED.fecha_ultima_llamada,
  updated_at = EXCLUDED.updated_at;

INSERT INTO public.utpl_registros (id_negocio, id_interno_negocio, cedula, nombre, apellido, modalidad, producto, telefono1, telefono2, telefono3, telefono4, telefono5, telefono6, intentos_llamada, win_tries, win_stamp, estado_flujo, fecha_reagenda, telefono_index, fecha_ultima_llamada, updated_at) VALUES
  ('SIM-0011', 'INT-0011', '1700000011', 'Andres', 'Morales', 'POSGRADO', 'BIOECONOMIA', '0999999003', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0012', 'INT-0012', '1700000012', 'Valentina', 'Ruiz', 'TECNOLÓGICO', 'CREACION AUDIOVISUAL DIGITAL', '0999999006', '0999999007', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0013', 'INT-0013', '1700000013', 'Jose', 'Ortiz', 'MODALIDAD EN LINEA', 'EDUCACION BASICA', '0999999009', '0999999010', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0014', 'INT-0014', '1700000014', 'Camila', 'Castro', 'POSGRADO', 'DERECHO TRIBUTARIO', '0999999012', '0999999013', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0015', 'INT-0015', '1700000015', 'Miguel', 'Herrera', 'TECNOLÓGICO', 'MARKETING TURISTICO DIGITAL', '0999999016', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0016', 'INT-0016', '1700000016', 'Daniela', 'Medina', 'MODALIDAD EN LINEA', 'PSICOLOGIA', '0999999019', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0017', 'INT-0017', '1700000017', 'Fernando', 'Reyes', 'POSGRADO', 'GESTION DE LA CALIDAD', '0999999022', '0999999023', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0018', 'INT-0018', '1700000018', 'Gabriela', 'Mendoza', 'TECNOLÓGICO', 'MODELADO BIM', '0999999025', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0019', 'INT-0019', '1700000019', 'Javier', 'Silva', 'MODALIDAD EN LINEA', 'COMUNICACION', '0999999028', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z'),
  ('SIM-0020', 'INT-0020', '1700000020', 'Paola', 'Paredes', 'POSGRADO', 'DERECHO TRIBUTARIO', '0999999001', '0999999002', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.858Z')
ON CONFLICT (id_negocio) DO UPDATE SET
  id_interno_negocio = EXCLUDED.id_interno_negocio,
  intentos_llamada = EXCLUDED.intentos_llamada,
  win_tries = EXCLUDED.win_tries,
  win_stamp = EXCLUDED.win_stamp,
  estado_flujo = EXCLUDED.estado_flujo,
  fecha_reagenda = EXCLUDED.fecha_reagenda,
  telefono_index = EXCLUDED.telefono_index,
  fecha_ultima_llamada = EXCLUDED.fecha_ultima_llamada,
  updated_at = EXCLUDED.updated_at;

INSERT INTO public.utpl_registros (id_negocio, id_interno_negocio, cedula, nombre, apellido, modalidad, producto, telefono1, telefono2, telefono3, telefono4, telefono5, telefono6, intentos_llamada, win_tries, win_stamp, estado_flujo, fecha_reagenda, telefono_index, fecha_ultima_llamada, updated_at) VALUES
  ('SIM-0021', 'INT-0021', '1700000021', 'Victor', 'Perez', 'TECNOLÓGICO', 'CONTABILIDAD Y ASESORIA TRIBUTARIA', '0999999003', '', '', '', '', '', '3', '0', '', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '3', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0022', 'INT-0022', '1700000022', 'Rosa', 'Gomez', 'MODALIDAD EN LINEA', 'TURISMO', '0999999006', '0999999007', '', '', '', '', '4', '1', 'MANANA_2026-05-21', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '4', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0023', 'INT-0023', '1700000023', 'Oscar', 'Lopez', 'POSGRADO', 'GERENCIA DE INSTITUCIONES DE SALUD', '0999999009', '0999999010', '', '', '', '', '5', '2', '', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '5', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0024', 'INT-0024', '1700000024', 'Natalia', 'Rodriguez', 'TECNOLÓGICO', 'NEGOCIACION Y VENTAS', '0999999012', '0999999013', '', '', '', '', '6', '0', 'MANANA_2026-05-23', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0025', 'INT-0025', '1700000025', 'Roberto', 'Martinez', 'MODALIDAD EN LINEA', 'ADMINISTRACION DE EMPRESAS', '0999999016', '', '', '', '', '', '7', '1', '', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0026', 'INT-0026', '1700000026', 'Adriana', 'Sanchez', 'POSGRADO', 'BIOECONOMIA', '0999999019', '', '', '', '', '', '8', '2', 'MANANA_2026-05-25', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '2', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0027', 'INT-0027', '1700000027', 'Gustavo', 'Torres', 'TECNOLÓGICO', 'MARKETING TURISTICO DIGITAL', '0999999022', '0999999023', '', '', '', '', '3', '0', '', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '3', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0028', 'INT-0028', '1700000028', 'Monica', 'Ramirez', 'MODALIDAD EN LINEA', 'ECONOMIA', '0999999025', '', '', '', '', '', '4', '1', 'MANANA_2026-05-27', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '4', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0029', 'INT-0029', '1700000029', 'Ricardo', 'Flores', 'POSGRADO', 'SEGURIDAD INDUSTRIAL', '0999999028', '', '', '', '', '', '5', '2', '', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '5', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0030', 'INT-0030', '1700000030', 'Tatiana', 'Vargas', 'TECNOLÓGICO', 'NEGOCIACION Y VENTAS', '0999999001', '0999999002', '', '', '', '', '6', '0', 'MANANA_2026-05-29', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z')
ON CONFLICT (id_negocio) DO UPDATE SET
  id_interno_negocio = EXCLUDED.id_interno_negocio,
  intentos_llamada = EXCLUDED.intentos_llamada,
  win_tries = EXCLUDED.win_tries,
  win_stamp = EXCLUDED.win_stamp,
  estado_flujo = EXCLUDED.estado_flujo,
  fecha_reagenda = EXCLUDED.fecha_reagenda,
  telefono_index = EXCLUDED.telefono_index,
  fecha_ultima_llamada = EXCLUDED.fecha_ultima_llamada,
  updated_at = EXCLUDED.updated_at;

INSERT INTO public.utpl_registros (id_negocio, id_interno_negocio, cedula, nombre, apellido, modalidad, producto, telefono1, telefono2, telefono3, telefono4, telefono5, telefono6, intentos_llamada, win_tries, win_stamp, estado_flujo, fecha_reagenda, telefono_index, fecha_ultima_llamada, updated_at) VALUES
  ('SIM-0031', 'INT-0031', '1700000031', 'Juan', 'Morales', 'MODALIDAD EN LINEA', 'TECNOLOGIAS DE LA INFORMACION', '0999999004', '0999999005', '', '', '', '', '7', '1', '', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0032', 'INT-0032', '1700000032', 'Maria', 'Ruiz', 'POSGRADO', 'DERECHO CONSTITUCIONAL', '0999999008', '', '', '', '', '', '8', '2', 'MANANA_2026-05-31', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '2', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0033', 'INT-0033', '1700000033', 'Carlos', 'Ortiz', 'TECNOLÓGICO', 'NEGOCIACION Y VENTAS', '0999999011', '', '', '', '', '', '3', '0', '', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '3', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0034', 'INT-0034', '1700000034', 'Ana', 'Castro', 'MODALIDAD EN LINEA', 'TURISMO', '0999999014', '0999999015', '', '', '', '', '4', '1', 'MANANA_2026-05-33', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '4', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0035', 'INT-0035', '1700000035', 'Pedro', 'Herrera', 'POSGRADO', 'GERENCIA DE INSTITUCIONES DE SALUD', '0999999017', '0999999018', '', '', '', '', '5', '2', '', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '5', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0036', 'INT-0036', '1700000036', 'Laura', 'Medina', 'TECNOLÓGICO', 'NEGOCIACION Y VENTAS', '0999999026', '0999999027', '', '', '', '', '6', '3', 'MANANA_2026-05-20', 'REINTENTAR', '2026-06-03T14:30:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0037', 'INT-0037', '1700000037', 'Luis', 'Reyes', 'MODALIDAD EN LINEA', 'ECONOMIA', '0999999029', '0999999030', '', '', '', '', '7', '3', 'MANANA_2026-05-21', 'REINTENTAR', '2026-06-03T14:30:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0038', 'INT-0038', '1700000038', 'Sofia', 'Mendoza', 'POSGRADO', 'DERECHO CONSTITUCIONAL', '0999999003', '', '', '', '', '', '8', '3', 'MANANA_2026-05-22', 'REINTENTAR', '2026-06-03T14:30:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0039', 'INT-0039', '1700000039', 'Diego', 'Silva', 'TECNOLÓGICO', 'MARKETING TURISTICO DIGITAL', '0999999006', '0999999007', '', '', '', '', '9', '3', 'MANANA_2026-05-23', 'REINTENTAR', '2026-06-03T14:30:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0040', 'INT-0040', '1700000040', 'Elena', 'Paredes', 'MODALIDAD EN LINEA', 'FINANZAS', '0999999009', '0999999010', '', '', '', '', '10', '3', 'MANANA_2026-05-24', 'REINTENTAR', '2026-06-03T14:30:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z')
ON CONFLICT (id_negocio) DO UPDATE SET
  id_interno_negocio = EXCLUDED.id_interno_negocio,
  intentos_llamada = EXCLUDED.intentos_llamada,
  win_tries = EXCLUDED.win_tries,
  win_stamp = EXCLUDED.win_stamp,
  estado_flujo = EXCLUDED.estado_flujo,
  fecha_reagenda = EXCLUDED.fecha_reagenda,
  telefono_index = EXCLUDED.telefono_index,
  fecha_ultima_llamada = EXCLUDED.fecha_ultima_llamada,
  updated_at = EXCLUDED.updated_at;

INSERT INTO public.utpl_registros (id_negocio, id_interno_negocio, cedula, nombre, apellido, modalidad, producto, telefono1, telefono2, telefono3, telefono4, telefono5, telefono6, intentos_llamada, win_tries, win_stamp, estado_flujo, fecha_reagenda, telefono_index, fecha_ultima_llamada, updated_at) VALUES
  ('SIM-0041', 'INT-0041', '1700000041', 'Andres', 'Perez', 'POSGRADO', 'GERENCIA DE INSTITUCIONES DE SALUD', '0999999012', '0999999013', '', '', '', '', '6', '3', 'MANANA_2026-05-25', 'REINTENTAR', '2026-06-04T14:30:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0042', 'INT-0042', '1700000042', 'Valentina', 'Gomez', 'TECNOLÓGICO', 'NEGOCIACION Y VENTAS', '0999999016', '', '', '', '', '', '7', '3', 'MANANA_2026-05-26', 'REINTENTAR', '2026-06-04T14:30:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0043', 'INT-0043', '1700000043', 'Jose', 'Lopez', 'MODALIDAD EN LINEA', 'TECNOLOGIAS DE LA INFORMACION', '0999999019', '', '', '', '', '', '8', '3', 'MANANA_2026-05-27', 'REINTENTAR', '2026-06-04T14:30:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0044', 'INT-0044', '1700000044', 'Camila', 'Rodriguez', 'POSGRADO', 'GERENCIA DE INSTITUCIONES DE SALUD', '0999999022', '0999999023', '', '', '', '', '9', '3', 'MANANA_2026-05-28', 'REINTENTAR', '2026-06-04T14:30:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0045', 'INT-0045', '1700000045', 'Miguel', 'Martinez', 'TECNOLÓGICO', 'MODELADO BIM', '0999999025', '', '', '', '', '', '10', '3', 'MANANA_2026-05-29', 'REINTENTAR', '2026-06-04T14:30:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0046', 'INT-0046', '1700000046', 'Daniela', 'Sanchez', 'MODALIDAD EN LINEA', 'FINANZAS', '0999999012', '0999999013', '', '', '', '', '14', '0', 'TARDE_2026-05-22', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '2', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0047', 'INT-0047', '1700000047', 'Fernando', 'Torres', 'POSGRADO', 'GERENCIA DE INSTITUCIONES DE SALUD', '0999999016', '', '', '', '', '', '15', '1', 'TARDE_2026-05-23', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0048', 'INT-0048', '1700000048', 'Gabriela', 'Ramirez', 'TECNOLÓGICO', 'MARKETING TURISTICO DIGITAL', '0999999019', '', '', '', '', '', '14', '2', 'TARDE_2026-05-24', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0049', 'INT-0049', '1700000049', 'Javier', 'Flores', 'MODALIDAD EN LINEA', 'TURISMO', '0999999022', '0999999023', '', '', '', '', '15', '0', 'TARDE_2026-05-25', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0050', 'INT-0050', '1700000050', 'Paola', 'Vargas', 'POSGRADO', 'DERECHO CONSTITUCIONAL', '0999999025', '', '', '', '', '', '14', '1', 'TARDE_2026-05-26', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z')
ON CONFLICT (id_negocio) DO UPDATE SET
  id_interno_negocio = EXCLUDED.id_interno_negocio,
  intentos_llamada = EXCLUDED.intentos_llamada,
  win_tries = EXCLUDED.win_tries,
  win_stamp = EXCLUDED.win_stamp,
  estado_flujo = EXCLUDED.estado_flujo,
  fecha_reagenda = EXCLUDED.fecha_reagenda,
  telefono_index = EXCLUDED.telefono_index,
  fecha_ultima_llamada = EXCLUDED.fecha_ultima_llamada,
  updated_at = EXCLUDED.updated_at;

INSERT INTO public.utpl_registros (id_negocio, id_interno_negocio, cedula, nombre, apellido, modalidad, producto, telefono1, telefono2, telefono3, telefono4, telefono5, telefono6, intentos_llamada, win_tries, win_stamp, estado_flujo, fecha_reagenda, telefono_index, fecha_ultima_llamada, updated_at) VALUES
  ('SIM-0051', 'INT-0051', '1700000051', 'Victor', 'Morales', 'TECNOLÓGICO', 'NEGOCIACION Y VENTAS', '0999999028', '', '', '', '', '', '15', '2', 'TARDE_2026-05-27', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '2', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0052', 'INT-0052', '1700000052', 'Rosa', 'Ruiz', 'MODALIDAD EN LINEA', 'TURISMO', '0999999001', '0999999002', '', '', '', '', '14', '0', 'TARDE_2026-05-28', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '2', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0053', 'INT-0053', '1700000053', 'Oscar', 'Ortiz', 'POSGRADO', 'GESTION DE LA CALIDAD', '0999999004', '0999999005', '', '', '', '', '15', '1', 'TARDE_2026-05-29', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0054', 'INT-0054', '1700000054', 'Natalia', 'Castro', 'TECNOLÓGICO', 'NEGOCIACION Y VENTAS', '0999999008', '', '', '', '', '', '14', '2', 'TARDE_2026-05-30', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0055', 'INT-0055', '1700000055', 'Roberto', 'Herrera', 'MODALIDAD EN LINEA', 'ECONOMIA', '0999999011', '', '', '', '', '', '15', '0', 'TARDE_2026-05-31', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0056', 'INT-0056', '1700000056', 'Adriana', 'Medina', 'POSGRADO', 'DERECHO PENAL', '0999999014', '0999999015', '', '', '', '', '14', '1', 'TARDE_2026-05-22', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0057', 'INT-0057', '1700000057', 'Gustavo', 'Reyes', 'TECNOLÓGICO', 'CREACION AUDIOVISUAL DIGITAL', '0999999017', '0999999018', '', '', '', '', '15', '2', 'TARDE_2026-05-23', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '2', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0058', 'INT-0058', '1700000058', 'Monica', 'Mendoza', 'MODALIDAD EN LINEA', 'TECNOLOGIAS DE LA INFORMACION', '0999999020', '0999999021', '', '', '', '', '14', '0', 'TARDE_2026-05-24', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '2', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0059', 'INT-0059', '1700000059', 'Ricardo', 'Silva', 'POSGRADO', 'DERECHO CONSTITUCIONAL', '0999999024', '', '', '', '', '', '15', '1', 'TARDE_2026-05-25', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0060', 'INT-0060', '1700000060', 'Tatiana', 'Paredes', 'TECNOLÓGICO', 'MODELADO BIM', '0999999026', '0999999027', '', '', '', '', '14', '2', 'TARDE_2026-05-26', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z')
ON CONFLICT (id_negocio) DO UPDATE SET
  id_interno_negocio = EXCLUDED.id_interno_negocio,
  intentos_llamada = EXCLUDED.intentos_llamada,
  win_tries = EXCLUDED.win_tries,
  win_stamp = EXCLUDED.win_stamp,
  estado_flujo = EXCLUDED.estado_flujo,
  fecha_reagenda = EXCLUDED.fecha_reagenda,
  telefono_index = EXCLUDED.telefono_index,
  fecha_ultima_llamada = EXCLUDED.fecha_ultima_llamada,
  updated_at = EXCLUDED.updated_at;

INSERT INTO public.utpl_registros (id_negocio, id_interno_negocio, cedula, nombre, apellido, modalidad, producto, telefono1, telefono2, telefono3, telefono4, telefono5, telefono6, intentos_llamada, win_tries, win_stamp, estado_flujo, fecha_reagenda, telefono_index, fecha_ultima_llamada, updated_at) VALUES
  ('SIM-0061', 'INT-0061', '1700000061', 'Juan', 'Perez', 'MODALIDAD EN LINEA', 'DERECHO', '0999999006', '0999999007', '', '', '', '', '16', '3', 'NOCHE_2026-05-27', 'REINTENTAR', '2026-06-04T00:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0062', 'INT-0062', '1700000062', 'Maria', 'Gomez', 'POSGRADO', 'BIOECONOMIA', '0999999009', '0999999010', '', '', '', '', '16', '3', 'NOCHE_2026-05-27', 'REINTENTAR', '2026-06-04T00:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0063', 'INT-0063', '1700000063', 'Carlos', 'Lopez', 'TECNOLÓGICO', 'CREACION AUDIOVISUAL DIGITAL', '0999999012', '0999999013', '', '', '', '', '16', '3', 'NOCHE_2026-05-27', 'REINTENTAR', '2026-06-04T00:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0064', 'INT-0064', '1700000064', 'Ana', 'Rodriguez', 'MODALIDAD EN LINEA', 'ADMINISTRACION DE EMPRESAS', '0999999016', '', '', '', '', '', '16', '3', 'NOCHE_2026-05-27', 'REINTENTAR', '2026-06-04T00:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0065', 'INT-0065', '1700000065', 'Pedro', 'Martinez', 'POSGRADO', 'GESTION FINANCIERA', '0999999019', '', '', '', '', '', '16', '3', 'NOCHE_2026-05-27', 'REINTENTAR', '2026-06-04T00:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.858Z'),
  ('SIM-0066', '', '1700000066', 'Laura', 'Sanchez', 'TECNOLÓGICO', 'CREACION AUDIOVISUAL DIGITAL', '', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z'),
  ('SIM-0067', '', '1700000067', 'Luis', 'Torres', 'MODALIDAD EN LINEA', 'EDUCACION BASICA', '', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z'),
  ('SIM-0068', '', '1700000068', 'Sofia', 'Ramirez', 'POSGRADO', 'BIOECONOMIA', '', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z'),
  ('SIM-0069', '', '1700000069', 'Diego', 'Flores', 'TECNOLÓGICO', 'MODELADO BIM', '', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z'),
  ('SIM-0070', '', '1700000070', 'Elena', 'Vargas', 'MODALIDAD EN LINEA', 'TURISMO', '', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z')
ON CONFLICT (id_negocio) DO UPDATE SET
  id_interno_negocio = EXCLUDED.id_interno_negocio,
  intentos_llamada = EXCLUDED.intentos_llamada,
  win_tries = EXCLUDED.win_tries,
  win_stamp = EXCLUDED.win_stamp,
  estado_flujo = EXCLUDED.estado_flujo,
  fecha_reagenda = EXCLUDED.fecha_reagenda,
  telefono_index = EXCLUDED.telefono_index,
  fecha_ultima_llamada = EXCLUDED.fecha_ultima_llamada,
  updated_at = EXCLUDED.updated_at;

INSERT INTO public.utpl_registros (id_negocio, id_interno_negocio, cedula, nombre, apellido, modalidad, producto, telefono1, telefono2, telefono3, telefono4, telefono5, telefono6, intentos_llamada, win_tries, win_stamp, estado_flujo, fecha_reagenda, telefono_index, fecha_ultima_llamada, updated_at) VALUES
  ('SIM-0071', 'INT-0071', '1700000071', 'Andres', 'Morales', 'POSGRADO', 'GESTION FINANCIERA', '0999999022', '0999999023', '', '', '', '', '2', '0', '', 'REINTENTAR', '2026-06-05T14:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0072', 'INT-0072', '1700000072', 'Valentina', 'Ruiz', 'TECNOLÓGICO', 'MODELADO BIM', '0999999025', '', '', '', '', '', '3', '1', '', 'REINTENTAR', '2026-06-05T14:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0073', 'INT-0073', '1700000073', 'Jose', 'Ortiz', 'MODALIDAD EN LINEA', 'DERECHO', '0999999028', '', '', '', '', '', '4', '0', '', 'REINTENTAR', '2026-06-05T14:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0074', 'INT-0074', '1700000074', 'Camila', 'Castro', 'POSGRADO', 'SEGURIDAD INDUSTRIAL', '0999999001', '0999999002', '', '', '', '', '2', '1', '', 'REINTENTAR', '2026-06-05T14:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0075', 'INT-0075', '1700000075', 'Miguel', 'Herrera', 'TECNOLÓGICO', 'MARKETING TURISTICO DIGITAL', '0999999004', '0999999005', '', '', '', '', '3', '0', '', 'REINTENTAR', '2026-06-05T14:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0076', 'INT-0076', '1700000076', 'Daniela', 'Medina', 'MODALIDAD EN LINEA', 'DERECHO', '0999999008', '', '', '', '', '', '4', '1', '', 'REINTENTAR', '2026-06-05T14:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0077', 'INT-0077', '1700000077', 'Fernando', 'Reyes', 'POSGRADO', 'GESTION DE LA CALIDAD', '0999999011', '', '', '', '', '', '2', '0', '', 'REINTENTAR', '2026-06-05T14:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0078', 'INT-0078', '1700000078', 'Gabriela', 'Mendoza', 'TECNOLÓGICO', 'MODELADO BIM', '0999999014', '0999999015', '', '', '', '', '3', '1', '', 'REINTENTAR', '2026-06-05T14:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0079', 'INT-0079', '1700000079', 'Javier', 'Silva', 'MODALIDAD EN LINEA', 'DERECHO', '0999999017', '0999999018', '', '', '', '', '4', '0', '', 'REINTENTAR', '2026-06-05T14:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0080', 'INT-0080', '1700000080', 'Paola', 'Paredes', 'POSGRADO', 'BIOECONOMIA', '0999999020', '0999999021', '', '', '', '', '2', '1', '', 'REINTENTAR', '2026-06-05T14:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z')
ON CONFLICT (id_negocio) DO UPDATE SET
  id_interno_negocio = EXCLUDED.id_interno_negocio,
  intentos_llamada = EXCLUDED.intentos_llamada,
  win_tries = EXCLUDED.win_tries,
  win_stamp = EXCLUDED.win_stamp,
  estado_flujo = EXCLUDED.estado_flujo,
  fecha_reagenda = EXCLUDED.fecha_reagenda,
  telefono_index = EXCLUDED.telefono_index,
  fecha_ultima_llamada = EXCLUDED.fecha_ultima_llamada,
  updated_at = EXCLUDED.updated_at;

INSERT INTO public.utpl_registros (id_negocio, id_interno_negocio, cedula, nombre, apellido, modalidad, producto, telefono1, telefono2, telefono3, telefono4, telefono5, telefono6, intentos_llamada, win_tries, win_stamp, estado_flujo, fecha_reagenda, telefono_index, fecha_ultima_llamada, updated_at) VALUES
  ('SIM-0081', 'INT-0081', '1700000081', 'Victor', 'Perez', 'TECNOLÓGICO', 'NEGOCIACION Y VENTAS', '0999999008', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z'),
  ('SIM-0082', 'INT-0082', '1700000082', 'Rosa', 'Gomez', 'MODALIDAD EN LINEA', 'DERECHO', '0999999011', '', '', '', '', '', '3', '0', 'MANANA_2026-05-21', 'REINTENTAR', '2026-06-03T16:00:00.000Z', '1', '2026-06-03T16:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0083', 'INT-0083', '1700000083', 'Oscar', 'Lopez', 'POSGRADO', 'BIOECONOMIA', '0999999014', '0999999015', '', '', '', '', '6', '0', 'MANANA_2026-05-22', 'REINTENTAR', '2026-06-03T17:00:00.000Z', '0', '2026-06-03T17:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0084', 'INT-0084', '1700000084', 'Natalia', 'Rodriguez', 'TECNOLÓGICO', 'CONTABILIDAD Y ASESORIA TRIBUTARIA', '0999999017', '0999999018', '', '', '', '', '6', '0', 'MANANA_2026-05-23', 'REINTENTAR', '2026-06-03T18:00:00.000Z', '0', '2026-06-03T18:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0085', 'INT-0085', '1700000085', 'Roberto', 'Martinez', 'MODALIDAD EN LINEA', 'FINANZAS', '0999999020', '0999999021', '', '', '', '', '9', '0', 'MANANA_2026-05-24', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '1', '2026-06-03T19:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0086', 'INT-0086', '1700000086', 'Adriana', 'Sanchez', 'POSGRADO', 'GESTION FINANCIERA', '0999999024', '', '', '', '', '', '12', '0', 'MANANA_2026-05-25', 'REINTENTAR', '2026-06-03T20:00:00.000Z', '0', '2026-06-03T20:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0087', 'INT-0087', '1700000087', 'Gustavo', 'Torres', 'TECNOLÓGICO', 'CONTABILIDAD Y ASESORIA TRIBUTARIA', '0999999026', '0999999027', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z'),
  ('SIM-0088', 'INT-0088', '1700000088', 'Monica', 'Ramirez', 'MODALIDAD EN LINEA', 'TECNOLOGIAS DE LA INFORMACION', '0999999029', '0999999030', '', '', '', '', '3', '0', 'MANANA_2026-05-27', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '1', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0089', '', '1700000089', 'Ricardo', 'Flores', 'POSGRADO', 'GESTION FINANCIERA', '0999999003', '', '', '', '', '', '6', '0', 'MANANA_2026-05-28', 'REINTENTAR', '2026-06-03T16:00:00.000Z', '0', '2026-06-03T16:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0090', '', '1700000090', 'Tatiana', 'Vargas', 'TECNOLÓGICO', 'CREACION AUDIOVISUAL DIGITAL', '0999999006', '0999999007', '', '', '', '', '6', '0', 'MANANA_2026-05-29', 'REINTENTAR', '2026-06-03T17:00:00.000Z', '0', '2026-06-03T17:00:00.000Z', '2026-06-04T14:04:06.859Z')
ON CONFLICT (id_negocio) DO UPDATE SET
  id_interno_negocio = EXCLUDED.id_interno_negocio,
  intentos_llamada = EXCLUDED.intentos_llamada,
  win_tries = EXCLUDED.win_tries,
  win_stamp = EXCLUDED.win_stamp,
  estado_flujo = EXCLUDED.estado_flujo,
  fecha_reagenda = EXCLUDED.fecha_reagenda,
  telefono_index = EXCLUDED.telefono_index,
  fecha_ultima_llamada = EXCLUDED.fecha_ultima_llamada,
  updated_at = EXCLUDED.updated_at;

INSERT INTO public.utpl_registros (id_negocio, id_interno_negocio, cedula, nombre, apellido, modalidad, producto, telefono1, telefono2, telefono3, telefono4, telefono5, telefono6, intentos_llamada, win_tries, win_stamp, estado_flujo, fecha_reagenda, telefono_index, fecha_ultima_llamada, updated_at) VALUES
  ('SIM-0091', '', '1700000091', 'Juan', 'Morales', 'MODALIDAD EN LINEA', 'EDUCACION BASICA', '0999999009', '0999999010', '', '', '', '', '9', '0', 'MANANA_2026-05-20', 'REINTENTAR', '2026-06-03T18:00:00.000Z', '1', '2026-06-03T18:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0092', '', '1700000092', 'Maria', 'Ruiz', 'POSGRADO', 'GESTION DE LA CALIDAD', '0999999012', '0999999013', '', '', '', '', '12', '0', 'MANANA_2026-05-21', 'REINTENTAR', '2026-06-03T19:00:00.000Z', '0', '2026-06-03T19:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0093', '', '1700000093', 'Carlos', 'Ortiz', 'TECNOLÓGICO', 'MODELADO BIM', '0999999016', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z'),
  ('SIM-0094', '', '1700000094', 'Ana', 'Castro', 'MODALIDAD EN LINEA', 'ECONOMIA', '0999999019', '', '', '', '', '', '3', '0', 'MANANA_2026-05-23', 'REINTENTAR', '2026-06-03T21:00:00.000Z', '1', '2026-06-03T21:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0095', '', '1700000095', 'Pedro', 'Herrera', 'POSGRADO', 'DERECHO PENAL', '0999999022', '0999999023', '', '', '', '', '6', '0', 'MANANA_2026-05-24', 'REINTENTAR', '2026-06-03T15:00:00.000Z', '0', '2026-06-03T15:00:00.000Z', '2026-06-04T14:04:06.859Z'),
  ('SIM-0096', '', '1700000096', 'Laura', 'Medina', 'TECNOLÓGICO', 'MODELADO BIM', '0999999001', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z'),
  ('SIM-0097', '', '1700000097', 'Luis', 'Reyes', 'MODALIDAD EN LINEA', 'FINANZAS', '0999999004', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z'),
  ('SIM-0098', '', '1700000098', 'Sofia', 'Mendoza', 'POSGRADO', 'DERECHO TRIBUTARIO', '0999999008', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z'),
  ('SIM-0099', '', '1700000099', 'Diego', 'Silva', 'TECNOLÓGICO', 'NEGOCIACION Y VENTAS', '0999999011', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z'),
  ('SIM-0100', '', '1700000100', 'Elena', 'Paredes', 'MODALIDAD EN LINEA', 'COMUNICACION', '0999999014', '', '', '', '', '', '0', '0', '', 'PENDIENTE', NULL, '0', NULL, '2026-06-04T14:04:06.859Z')
ON CONFLICT (id_negocio) DO UPDATE SET
  id_interno_negocio = EXCLUDED.id_interno_negocio,
  intentos_llamada = EXCLUDED.intentos_llamada,
  win_tries = EXCLUDED.win_tries,
  win_stamp = EXCLUDED.win_stamp,
  estado_flujo = EXCLUDED.estado_flujo,
  fecha_reagenda = EXCLUDED.fecha_reagenda,
  telefono_index = EXCLUDED.telefono_index,
  fecha_ultima_llamada = EXCLUDED.fecha_ultima_llamada,
  updated_at = EXCLUDED.updated_at;

