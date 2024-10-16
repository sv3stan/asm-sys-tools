﻿# Резюме проекта на ассемблере для MS-DOS

## Описание

Данный проект включает в себя несколько программ, написанных на ассемблере для операционной системы MS-DOS. Каждая из программ реализует различные функции и демонстрирует возможности работы с системными ресурсами на низком уровне. Основные направления, охваченные проектом:

1. **Установка таймера**: 
   - Программа позволяет пользователю устанавливать таймер с возможностью настройки времени через параметры командной строки. Она отображает текущее время и генерирует звуковой сигнал при истечении установленного времени.

2. **Управление памятью**: 
   - Данная программа отображает информацию о сегментах памяти (MCB - Memory Control Block), включая их размеры и атрибуты. Она использует прерывания DOS для получения списка сегментов памяти и их характеристик, а также отображает эту информацию на экране в табличной форме.

3. **Работа с сетевыми протоколами**: 
   - Программа реализует клиент-серверное взаимодействие с использованием протоколов IPX и SPX, позволяя передавать файлы между узлами сети. Она проверяет наличие установленных драйверов, управляет передачей данных и обрабатывает возможные ошибки.

## Основные компоненты

- **Сегменты и переменные**: Программы используют сегменты кода и данных, а также массивы и строки для хранения информации и сообщений пользователю.
  
- **Процедуры и обработчики**: Каждая программа включает в себя несколько процедур, отвечающих за различные задачи: инициализацию, обработку ввода, передачу данных, управление прерываниями и отображение информации.

- **Обработка ошибок**: Все программы реализуют механизмы для отслеживания и обработки ошибок, что позволяет обеспечить надежность их работы.

## Заключение

Данный проект является примером применения ассемблера для решения практических задач, связанных с управлением временем, памятью и сетевыми взаимодействиями. Он предоставляет возможность изучения низкоуровневых операций и принципов работы операционной системы MS-DOS.
