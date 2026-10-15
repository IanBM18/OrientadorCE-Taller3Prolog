% --- Base de Conocimientos: Profesiones ---
% Se definen 10 profesiones.

profesion(ingenieria_computadores).
profesion(psicologia).
profesion(medicina).
profesion(derecho).
profesion(arquitectura).
profesion(administracion).
profesion(diseno_grafico).
profesion(biologia).
profesion(periodismo).
profesion(educacion_fisica).

% --- Afinidades y Fortalezas ---
% Estructura: afinidades(Profesion, [Lista de intereses]).

afinidades(ingenieria_computadores, [matematicas, tecnologia, resolver_problemas]).
afinidades(psicologia, [ayudar_personas, escuchar, empatia]).
afinidades(medicina, [ciencias_salud, ayudar_personas, biologia]).
afinidades(derecho, [lectura, debate, justicia]).
afinidades(arquitectura, [dibujo, matematicas, creatividad]).
afinidades(administracion, [liderazgo, finanzas, organizacion]).
afinidades(diseno_grafico, [creatividad, arte, tecnologia]).
afinidades(biologia, [naturaleza, investigacion, ciencias]).
afinidades(periodismo, [escribir, investigar, comunicacion]).
afinidades(educacion_fisica, [deportes, ensenanza, movimiento]).

% --- Aspectos Incompatibles / Preferencias contrarias ---
% Estructura: incompatibles(Profesion, [Lista de aspectos que no deben gustarle]).

incompatibles(ingenieria_computadores, [rechazo_tecnologia, aversion_matematicas]).
incompatibles(psicologia, [trabajo_aislado, falta_paciencia]).
incompatibles(medicina, [impresion_sangre, falta_empatia]).
incompatibles(derecho, [rechazo_lectura, miedo_hablar_publico]).
incompatibles(arquitectura, [rechazo_dibujo, desorden_espacial]).
incompatibles(administracion, [desorganizacion, rechazo_numeros]).
incompatibles(diseno_grafico, [rechazo_arte, falta_imaginacion]).
incompatibles(biologia, [rechazo_naturaleza, trabajo_encerrado]).
incompatibles(periodismo, [timidez_extrema, mala_redaccion]).
incompatibles(educacion_fisica, [sedentarismo, rechazo_deportes]).