-- sql/026_carga_proveedores.sql
--
-- Con la Agenda de Pagos ya vacia (sql/025), ningun proveedor tiene pagos
-- asociados -- se borra la lista completa de Proveedores y se carga de
-- cero con los 33 del Excel maestro. Si por alguna razon quedara algun
-- proveedor con pagos referenciados, el DELETE fallaria solo (la relacion
-- con proveedores_pagos lo protege), en vez de borrar datos con historial.

begin;

delete from proveedores;

insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('ABRAZADERAS NIBIA QUIÑONES /JORGE A', null, null, null, null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('AKRON - LUBRIOR LA SABANA SAS', '901962376-1', null, '3162926567', null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('ACUMULADORES DUNCAN SAS', '800236772-3', 'ÁNGEL', '3138483595', null, null, null, 'BANCOLOMBIA', 'corriente'::tipo_cuenta, '67300016442', '83745');
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('ARANI LTDA', '830139791-7', 'LUIS EDUARDO SANTOS', '3212074562', null, null, 'contabilidad@arani.com.co', 'BANCOLOMBIA', 'ahorros'::tipo_cuenta, '20235872285', null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('BATERMAX SAS', '901146357-1', null, null, null, null, null, 'BANCOLOMBIA', null, '94688827102', null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('BEG LUBRICANTES - ARINTIA GROUP S.A.S.', '900117244-9', 'JORGE GIL', '3143454567', 'NELSON FARIAS', '3160277804', null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('CABRERA', null, null, null, null, null, null, 'BANCOLOMBIA', 'corriente'::tipo_cuenta, '46783622973', null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('CARLOS SIERRA', null, null, null, null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('COLPAFILT - COLOMBIANA DE PARTES Y FILTROS S.A.S.', '900396456-9', 'XIMENA RUIZ', '3005712309', null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('COMERCIALIZADORA CAR FILT SAS.', '900454742-1', 'MIGUEL LOVERA', '3182587599', null, null, 'ventas@car-filt.com.co', 'BANCOLOMBIA', 'corriente'::tipo_cuenta, '63912996584', '82929');
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('COMERCIALIZADORA FRANIG SAS', '860516066', 'CARLOS DONATO', '3103295629', null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('DERCO COLOMBIA SAS', '900327290-9', 'DIEGO VARGAS', '3102252783', 'CORPORATIVO', '3102412923', null, 'BANCOLOMBIA', 'corriente'::tipo_cuenta, '03166351256', '45659');
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('DISMACOR COLOMBIA SAS', '800092138-3', 'FRANCY ARIAS', '3107807723', null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('ELF', '900425918-5', 'NELSON JAVIER DÍAZ', '3123588723', null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('INVERSIONES KOMER', '900410889-4', 'ROBERTO F', '3103126677', 'CORPORATIVO', '3007948380', 'servicioalcliente@inversioneskomer.com', 'BANCOLOMBIA', 'corriente'::tipo_cuenta, '13168586737', '65266');
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('JOSÉ SIERRA', null, null, null, null, null, null, 'NEQUI', null, '3112088952', null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('JULIO SUÁREZ', null, null, null, null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('LUBRIFILTROS', null, null, null, null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('LUBRILAG LA SABANA', null, null, null, null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('LUDELPA LUBRICANTES DEL PAÍS SAS', '830514973-9', 'XIOMARA FARFÁN', '3156120040', null, null, 'helenareyes@ludelpa.com', 'BANCOLOMBIA', 'corriente'::tipo_cuenta, '25035604124', '85548');
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('MOTO LUJOS', null, null, null, null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('OIL FILTER''S', '830038805-8', 'LILIANA', '3167424420', 'GERENCIA CARTERA', '3167424307', 'facturas@oilfilters.com.co', null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('PELÁEZ HERMANOS', '890101138-0', 'YOLANDA GUAYÓN', '3042858558', null, null, null, 'BANCOLOMBIA', 'corriente'::tipo_cuenta, '04410113822', null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('PREMIUM FILTERS SAS', null, null, null, null, null, null, 'BANCOLOMBIA', 'corriente'::tipo_cuenta, '04314966846', '7882');
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('ROYAL SOLUTIONS SAS', '830065905-0', null, '3212130327', null, null, 'royalsrecepcionpagos@gmail.com', 'BRE-B', null, '@8300659050-ROYALS SOLUTIONS SAS', null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('R&R', null, 'ELIANA', '3185896019', null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('SATLOCK LOGISTICA Y SEGURIDAD SAS', '900449459-1', 'IVAN MEDINA', '3106899016', null, null, 'facturacionproveedores@satlock.com', 'BANCOLOMBIA', 'corriente'::tipo_cuenta, '24172120866', null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('SHELL', null, 'ANGÉLICA ARANGO', '3102178281', 'César Mota', '3146892065', null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('SIMONIZ EN COLOMBIA S.A.', '800203984-6', 'ZAMAEL G', '3132489481', 'EDLEIN RODRÍGUEZ', '3219606079', null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('SWISSLUB SAS', '900732297-6', 'DIANA', '3208315774', null, null, null, 'BANCOLOMBIA', 'corriente'::tipo_cuenta, '23726617222', '57915');
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('TAMBOR MX', null, 'YAZMÍN GARCÍA', '3208557862', null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('TECNICAUCHOS', null, null, null, null, null, null, null, null, null, null);
insert into proveedores (nombre, nit, contacto, telefono, contacto_2, telefono_2, correo, banco, tipo_cuenta, numero_cuenta, convenio) values ('TRIFA ELCIRA PABLA CARVAJAL', '52835692-1', 'CAMPO ELÍAS AGUILAR', '3106280234', null, null, 'trifarepuestos@hotmail.com', 'BANCOLOMBIA', 'ahorros'::tipo_cuenta, '10866782593', null);

commit;
