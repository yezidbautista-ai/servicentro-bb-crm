-- sql/028_nuevo_proveedor_plastmet.sql
--
-- Proveedor nuevo detectado en el Excel de Agenda de Pagos 2026, no estaba
-- en la lista original de 33 proveedores. Solo se conoce el nombre por
-- ahora -- el resto de sus datos (NIT, contacto, banco, etc.) se puede
-- completar despues editando su ficha en Proveedores.

insert into proveedores (nombre) values ('ABRAZADERAS PLAST-MET');
