-- sql/016_datafono_codigo.sql
--
-- Le da un `codigo` a la cuenta "Datáfono" (antes null) para poder derivar
-- el método de pago automáticamente a partir de la cuenta elegida en el
-- flujo de "Marcar como pagado" de Agenda de Pagos, sin pedir los dos
-- campos por separado.

update cuentas set codigo = 'datafono' where nombre = 'Datáfono';
