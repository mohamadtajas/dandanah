// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SurahsTable extends Surahs with TableInfo<$SurahsTable, Surah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _englishNameMeta = const VerificationMeta(
    'englishName',
  );
  @override
  late final GeneratedColumn<String> englishName = GeneratedColumn<String>(
    'english_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahCountMeta = const VerificationMeta(
    'ayahCount',
  );
  @override
  late final GeneratedColumn<int> ayahCount = GeneratedColumn<int>(
    'ayah_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revelationMeta = const VerificationMeta(
    'revelation',
  );
  @override
  late final GeneratedColumn<String> revelation = GeneratedColumn<String>(
    'revelation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bismillahMeta = const VerificationMeta(
    'bismillah',
  );
  @override
  late final GeneratedColumn<String> bismillah = GeneratedColumn<String>(
    'bismillah',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    number,
    name,
    englishName,
    meaning,
    ayahCount,
    revelation,
    bismillah,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Surah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('english_name')) {
      context.handle(
        _englishNameMeta,
        englishName.isAcceptableOrUnknown(
          data['english_name']!,
          _englishNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_englishNameMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('ayah_count')) {
      context.handle(
        _ayahCountMeta,
        ayahCount.isAcceptableOrUnknown(data['ayah_count']!, _ayahCountMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahCountMeta);
    }
    if (data.containsKey('revelation')) {
      context.handle(
        _revelationMeta,
        revelation.isAcceptableOrUnknown(data['revelation']!, _revelationMeta),
      );
    } else if (isInserting) {
      context.missing(_revelationMeta);
    }
    if (data.containsKey('bismillah')) {
      context.handle(
        _bismillahMeta,
        bismillah.isAcceptableOrUnknown(data['bismillah']!, _bismillahMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {number};
  @override
  Surah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Surah(
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      englishName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_name'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      ayahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_count'],
      )!,
      revelation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revelation'],
      )!,
      bismillah: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bismillah'],
      ),
    );
  }

  @override
  $SurahsTable createAlias(String alias) {
    return $SurahsTable(attachedDatabase, alias);
  }
}

class Surah extends DataClass implements Insertable<Surah> {
  final int number;
  final String name;
  final String englishName;
  final String meaning;
  final int ayahCount;
  final String revelation;
  final String? bismillah;
  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.meaning,
    required this.ayahCount,
    required this.revelation,
    this.bismillah,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['number'] = Variable<int>(number);
    map['name'] = Variable<String>(name);
    map['english_name'] = Variable<String>(englishName);
    map['meaning'] = Variable<String>(meaning);
    map['ayah_count'] = Variable<int>(ayahCount);
    map['revelation'] = Variable<String>(revelation);
    if (!nullToAbsent || bismillah != null) {
      map['bismillah'] = Variable<String>(bismillah);
    }
    return map;
  }

  SurahsCompanion toCompanion(bool nullToAbsent) {
    return SurahsCompanion(
      number: Value(number),
      name: Value(name),
      englishName: Value(englishName),
      meaning: Value(meaning),
      ayahCount: Value(ayahCount),
      revelation: Value(revelation),
      bismillah: bismillah == null && nullToAbsent
          ? const Value.absent()
          : Value(bismillah),
    );
  }

  factory Surah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Surah(
      number: serializer.fromJson<int>(json['number']),
      name: serializer.fromJson<String>(json['name']),
      englishName: serializer.fromJson<String>(json['englishName']),
      meaning: serializer.fromJson<String>(json['meaning']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
      revelation: serializer.fromJson<String>(json['revelation']),
      bismillah: serializer.fromJson<String?>(json['bismillah']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'number': serializer.toJson<int>(number),
      'name': serializer.toJson<String>(name),
      'englishName': serializer.toJson<String>(englishName),
      'meaning': serializer.toJson<String>(meaning),
      'ayahCount': serializer.toJson<int>(ayahCount),
      'revelation': serializer.toJson<String>(revelation),
      'bismillah': serializer.toJson<String?>(bismillah),
    };
  }

  Surah copyWith({
    int? number,
    String? name,
    String? englishName,
    String? meaning,
    int? ayahCount,
    String? revelation,
    Value<String?> bismillah = const Value.absent(),
  }) => Surah(
    number: number ?? this.number,
    name: name ?? this.name,
    englishName: englishName ?? this.englishName,
    meaning: meaning ?? this.meaning,
    ayahCount: ayahCount ?? this.ayahCount,
    revelation: revelation ?? this.revelation,
    bismillah: bismillah.present ? bismillah.value : this.bismillah,
  );
  Surah copyWithCompanion(SurahsCompanion data) {
    return Surah(
      number: data.number.present ? data.number.value : this.number,
      name: data.name.present ? data.name.value : this.name,
      englishName: data.englishName.present
          ? data.englishName.value
          : this.englishName,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
      revelation: data.revelation.present
          ? data.revelation.value
          : this.revelation,
      bismillah: data.bismillah.present ? data.bismillah.value : this.bismillah,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Surah(')
          ..write('number: $number, ')
          ..write('name: $name, ')
          ..write('englishName: $englishName, ')
          ..write('meaning: $meaning, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('revelation: $revelation, ')
          ..write('bismillah: $bismillah')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    number,
    name,
    englishName,
    meaning,
    ayahCount,
    revelation,
    bismillah,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Surah &&
          other.number == this.number &&
          other.name == this.name &&
          other.englishName == this.englishName &&
          other.meaning == this.meaning &&
          other.ayahCount == this.ayahCount &&
          other.revelation == this.revelation &&
          other.bismillah == this.bismillah);
}

class SurahsCompanion extends UpdateCompanion<Surah> {
  final Value<int> number;
  final Value<String> name;
  final Value<String> englishName;
  final Value<String> meaning;
  final Value<int> ayahCount;
  final Value<String> revelation;
  final Value<String?> bismillah;
  const SurahsCompanion({
    this.number = const Value.absent(),
    this.name = const Value.absent(),
    this.englishName = const Value.absent(),
    this.meaning = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.revelation = const Value.absent(),
    this.bismillah = const Value.absent(),
  });
  SurahsCompanion.insert({
    this.number = const Value.absent(),
    required String name,
    required String englishName,
    required String meaning,
    required int ayahCount,
    required String revelation,
    this.bismillah = const Value.absent(),
  }) : name = Value(name),
       englishName = Value(englishName),
       meaning = Value(meaning),
       ayahCount = Value(ayahCount),
       revelation = Value(revelation);
  static Insertable<Surah> custom({
    Expression<int>? number,
    Expression<String>? name,
    Expression<String>? englishName,
    Expression<String>? meaning,
    Expression<int>? ayahCount,
    Expression<String>? revelation,
    Expression<String>? bismillah,
  }) {
    return RawValuesInsertable({
      if (number != null) 'number': number,
      if (name != null) 'name': name,
      if (englishName != null) 'english_name': englishName,
      if (meaning != null) 'meaning': meaning,
      if (ayahCount != null) 'ayah_count': ayahCount,
      if (revelation != null) 'revelation': revelation,
      if (bismillah != null) 'bismillah': bismillah,
    });
  }

  SurahsCompanion copyWith({
    Value<int>? number,
    Value<String>? name,
    Value<String>? englishName,
    Value<String>? meaning,
    Value<int>? ayahCount,
    Value<String>? revelation,
    Value<String?>? bismillah,
  }) {
    return SurahsCompanion(
      number: number ?? this.number,
      name: name ?? this.name,
      englishName: englishName ?? this.englishName,
      meaning: meaning ?? this.meaning,
      ayahCount: ayahCount ?? this.ayahCount,
      revelation: revelation ?? this.revelation,
      bismillah: bismillah ?? this.bismillah,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (englishName.present) {
      map['english_name'] = Variable<String>(englishName.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    if (revelation.present) {
      map['revelation'] = Variable<String>(revelation.value);
    }
    if (bismillah.present) {
      map['bismillah'] = Variable<String>(bismillah.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurahsCompanion(')
          ..write('number: $number, ')
          ..write('name: $name, ')
          ..write('englishName: $englishName, ')
          ..write('meaning: $meaning, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('revelation: $revelation, ')
          ..write('bismillah: $bismillah')
          ..write(')'))
        .toString();
  }
}

class $AyahsTable extends Ayahs with TableInfo<$AyahsTable, Ayah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES surahs (number)',
    ),
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _juzMeta = const VerificationMeta('juz');
  @override
  late final GeneratedColumn<int> juz = GeneratedColumn<int>(
    'juz',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sajdaMeta = const VerificationMeta('sajda');
  @override
  late final GeneratedColumn<bool> sajda = GeneratedColumn<bool>(
    'sajda',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sajda" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [surah, ayah, body, juz, page, sajda];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ayah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('juz')) {
      context.handle(
        _juzMeta,
        juz.isAcceptableOrUnknown(data['juz']!, _juzMeta),
      );
    } else if (isInserting) {
      context.missing(_juzMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('sajda')) {
      context.handle(
        _sajdaMeta,
        sajda.isAcceptableOrUnknown(data['sajda']!, _sajdaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surah, ayah};
  @override
  Ayah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ayah(
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      juz: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}juz'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      sajda: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sajda'],
      )!,
    );
  }

  @override
  $AyahsTable createAlias(String alias) {
    return $AyahsTable(attachedDatabase, alias);
  }
}

class Ayah extends DataClass implements Insertable<Ayah> {
  final int surah;
  final int ayah;
  final String body;
  final int juz;
  final int page;
  final bool sajda;
  const Ayah({
    required this.surah,
    required this.ayah,
    required this.body,
    required this.juz,
    required this.page,
    required this.sajda,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['body'] = Variable<String>(body);
    map['juz'] = Variable<int>(juz);
    map['page'] = Variable<int>(page);
    map['sajda'] = Variable<bool>(sajda);
    return map;
  }

  AyahsCompanion toCompanion(bool nullToAbsent) {
    return AyahsCompanion(
      surah: Value(surah),
      ayah: Value(ayah),
      body: Value(body),
      juz: Value(juz),
      page: Value(page),
      sajda: Value(sajda),
    );
  }

  factory Ayah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ayah(
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      body: serializer.fromJson<String>(json['body']),
      juz: serializer.fromJson<int>(json['juz']),
      page: serializer.fromJson<int>(json['page']),
      sajda: serializer.fromJson<bool>(json['sajda']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'body': serializer.toJson<String>(body),
      'juz': serializer.toJson<int>(juz),
      'page': serializer.toJson<int>(page),
      'sajda': serializer.toJson<bool>(sajda),
    };
  }

  Ayah copyWith({
    int? surah,
    int? ayah,
    String? body,
    int? juz,
    int? page,
    bool? sajda,
  }) => Ayah(
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    body: body ?? this.body,
    juz: juz ?? this.juz,
    page: page ?? this.page,
    sajda: sajda ?? this.sajda,
  );
  Ayah copyWithCompanion(AyahsCompanion data) {
    return Ayah(
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      body: data.body.present ? data.body.value : this.body,
      juz: data.juz.present ? data.juz.value : this.juz,
      page: data.page.present ? data.page.value : this.page,
      sajda: data.sajda.present ? data.sajda.value : this.sajda,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ayah(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('body: $body, ')
          ..write('juz: $juz, ')
          ..write('page: $page, ')
          ..write('sajda: $sajda')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surah, ayah, body, juz, page, sajda);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ayah &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.body == this.body &&
          other.juz == this.juz &&
          other.page == this.page &&
          other.sajda == this.sajda);
}

class AyahsCompanion extends UpdateCompanion<Ayah> {
  final Value<int> surah;
  final Value<int> ayah;
  final Value<String> body;
  final Value<int> juz;
  final Value<int> page;
  final Value<bool> sajda;
  final Value<int> rowid;
  const AyahsCompanion({
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.body = const Value.absent(),
    this.juz = const Value.absent(),
    this.page = const Value.absent(),
    this.sajda = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AyahsCompanion.insert({
    required int surah,
    required int ayah,
    required String body,
    required int juz,
    required int page,
    this.sajda = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : surah = Value(surah),
       ayah = Value(ayah),
       body = Value(body),
       juz = Value(juz),
       page = Value(page);
  static Insertable<Ayah> custom({
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<String>? body,
    Expression<int>? juz,
    Expression<int>? page,
    Expression<bool>? sajda,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (body != null) 'body': body,
      if (juz != null) 'juz': juz,
      if (page != null) 'page': page,
      if (sajda != null) 'sajda': sajda,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AyahsCompanion copyWith({
    Value<int>? surah,
    Value<int>? ayah,
    Value<String>? body,
    Value<int>? juz,
    Value<int>? page,
    Value<bool>? sajda,
    Value<int>? rowid,
  }) {
    return AyahsCompanion(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      body: body ?? this.body,
      juz: juz ?? this.juz,
      page: page ?? this.page,
      sajda: sajda ?? this.sajda,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (juz.present) {
      map['juz'] = Variable<int>(juz.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (sajda.present) {
      map['sajda'] = Variable<bool>(sajda.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahsCompanion(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('body: $body, ')
          ..write('juz: $juz, ')
          ..write('page: $page, ')
          ..write('sajda: $sajda, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JuzsTable extends Juzs with TableInfo<$JuzsTable, Juz> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JuzsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES surahs (number)',
    ),
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahCountMeta = const VerificationMeta(
    'ayahCount',
  );
  @override
  late final GeneratedColumn<int> ayahCount = GeneratedColumn<int>(
    'ayah_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [number, surah, ayah, ayahCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'juzs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Juz> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('ayah_count')) {
      context.handle(
        _ayahCountMeta,
        ayahCount.isAcceptableOrUnknown(data['ayah_count']!, _ayahCountMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {number};
  @override
  Juz map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Juz(
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      ayahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_count'],
      )!,
    );
  }

  @override
  $JuzsTable createAlias(String alias) {
    return $JuzsTable(attachedDatabase, alias);
  }
}

class Juz extends DataClass implements Insertable<Juz> {
  final int number;
  final int surah;
  final int ayah;
  final int ayahCount;
  const Juz({
    required this.number,
    required this.surah,
    required this.ayah,
    required this.ayahCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['number'] = Variable<int>(number);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['ayah_count'] = Variable<int>(ayahCount);
    return map;
  }

  JuzsCompanion toCompanion(bool nullToAbsent) {
    return JuzsCompanion(
      number: Value(number),
      surah: Value(surah),
      ayah: Value(ayah),
      ayahCount: Value(ayahCount),
    );
  }

  factory Juz.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Juz(
      number: serializer.fromJson<int>(json['number']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'number': serializer.toJson<int>(number),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'ayahCount': serializer.toJson<int>(ayahCount),
    };
  }

  Juz copyWith({int? number, int? surah, int? ayah, int? ayahCount}) => Juz(
    number: number ?? this.number,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    ayahCount: ayahCount ?? this.ayahCount,
  );
  Juz copyWithCompanion(JuzsCompanion data) {
    return Juz(
      number: data.number.present ? data.number.value : this.number,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Juz(')
          ..write('number: $number, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('ayahCount: $ayahCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(number, surah, ayah, ayahCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Juz &&
          other.number == this.number &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.ayahCount == this.ayahCount);
}

class JuzsCompanion extends UpdateCompanion<Juz> {
  final Value<int> number;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> ayahCount;
  const JuzsCompanion({
    this.number = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.ayahCount = const Value.absent(),
  });
  JuzsCompanion.insert({
    this.number = const Value.absent(),
    required int surah,
    required int ayah,
    required int ayahCount,
  }) : surah = Value(surah),
       ayah = Value(ayah),
       ayahCount = Value(ayahCount);
  static Insertable<Juz> custom({
    Expression<int>? number,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? ayahCount,
  }) {
    return RawValuesInsertable({
      if (number != null) 'number': number,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (ayahCount != null) 'ayah_count': ayahCount,
    });
  }

  JuzsCompanion copyWith({
    Value<int>? number,
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? ayahCount,
  }) {
    return JuzsCompanion(
      number: number ?? this.number,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      ayahCount: ayahCount ?? this.ayahCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JuzsCompanion(')
          ..write('number: $number, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('ayahCount: $ayahCount')
          ..write(')'))
        .toString();
  }
}

class $QuranPagesTable extends QuranPages
    with TableInfo<$QuranPagesTable, QuranPage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuranPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES surahs (number)',
    ),
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [number, surah, ayah];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quran_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuranPage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {number};
  @override
  QuranPage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuranPage(
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
    );
  }

  @override
  $QuranPagesTable createAlias(String alias) {
    return $QuranPagesTable(attachedDatabase, alias);
  }
}

class QuranPage extends DataClass implements Insertable<QuranPage> {
  final int number;
  final int surah;
  final int ayah;
  const QuranPage({
    required this.number,
    required this.surah,
    required this.ayah,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['number'] = Variable<int>(number);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    return map;
  }

  QuranPagesCompanion toCompanion(bool nullToAbsent) {
    return QuranPagesCompanion(
      number: Value(number),
      surah: Value(surah),
      ayah: Value(ayah),
    );
  }

  factory QuranPage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuranPage(
      number: serializer.fromJson<int>(json['number']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'number': serializer.toJson<int>(number),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
    };
  }

  QuranPage copyWith({int? number, int? surah, int? ayah}) => QuranPage(
    number: number ?? this.number,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
  );
  QuranPage copyWithCompanion(QuranPagesCompanion data) {
    return QuranPage(
      number: data.number.present ? data.number.value : this.number,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuranPage(')
          ..write('number: $number, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(number, surah, ayah);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranPage &&
          other.number == this.number &&
          other.surah == this.surah &&
          other.ayah == this.ayah);
}

class QuranPagesCompanion extends UpdateCompanion<QuranPage> {
  final Value<int> number;
  final Value<int> surah;
  final Value<int> ayah;
  const QuranPagesCompanion({
    this.number = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
  });
  QuranPagesCompanion.insert({
    this.number = const Value.absent(),
    required int surah,
    required int ayah,
  }) : surah = Value(surah),
       ayah = Value(ayah);
  static Insertable<QuranPage> custom({
    Expression<int>? number,
    Expression<int>? surah,
    Expression<int>? ayah,
  }) {
    return RawValuesInsertable({
      if (number != null) 'number': number,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
    });
  }

  QuranPagesCompanion copyWith({
    Value<int>? number,
    Value<int>? surah,
    Value<int>? ayah,
  }) {
    return QuranPagesCompanion(
      number: number ?? this.number,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuranPagesCompanion(')
          ..write('number: $number, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah')
          ..write(')'))
        .toString();
  }
}

class $AdhkarCategoriesTable extends AdhkarCategories
    with TableInfo<$AdhkarCategoriesTable, AdhkarCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdhkarCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _featuredMeta = const VerificationMeta(
    'featured',
  );
  @override
  late final GeneratedColumn<bool> featured = GeneratedColumn<bool>(
    'featured',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("featured" IN (0, 1))',
    ),
  );
  static const VerificationMeta _streakKeyMeta = const VerificationMeta(
    'streakKey',
  );
  @override
  late final GeneratedColumn<String> streakKey = GeneratedColumn<String>(
    'streak_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    featured,
    streakKey,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adhkar_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdhkarCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('featured')) {
      context.handle(
        _featuredMeta,
        featured.isAcceptableOrUnknown(data['featured']!, _featuredMeta),
      );
    } else if (isInserting) {
      context.missing(_featuredMeta);
    }
    if (data.containsKey('streak_key')) {
      context.handle(
        _streakKeyMeta,
        streakKey.isAcceptableOrUnknown(data['streak_key']!, _streakKeyMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdhkarCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdhkarCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      featured: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}featured'],
      )!,
      streakKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}streak_key'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AdhkarCategoriesTable createAlias(String alias) {
    return $AdhkarCategoriesTable(attachedDatabase, alias);
  }
}

class AdhkarCategory extends DataClass implements Insertable<AdhkarCategory> {
  final String id;
  final String title;
  final bool featured;
  final String? streakKey;
  final int sortOrder;
  const AdhkarCategory({
    required this.id,
    required this.title,
    required this.featured,
    this.streakKey,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['featured'] = Variable<bool>(featured);
    if (!nullToAbsent || streakKey != null) {
      map['streak_key'] = Variable<String>(streakKey);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AdhkarCategoriesCompanion toCompanion(bool nullToAbsent) {
    return AdhkarCategoriesCompanion(
      id: Value(id),
      title: Value(title),
      featured: Value(featured),
      streakKey: streakKey == null && nullToAbsent
          ? const Value.absent()
          : Value(streakKey),
      sortOrder: Value(sortOrder),
    );
  }

  factory AdhkarCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdhkarCategory(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      featured: serializer.fromJson<bool>(json['featured']),
      streakKey: serializer.fromJson<String?>(json['streakKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'featured': serializer.toJson<bool>(featured),
      'streakKey': serializer.toJson<String?>(streakKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AdhkarCategory copyWith({
    String? id,
    String? title,
    bool? featured,
    Value<String?> streakKey = const Value.absent(),
    int? sortOrder,
  }) => AdhkarCategory(
    id: id ?? this.id,
    title: title ?? this.title,
    featured: featured ?? this.featured,
    streakKey: streakKey.present ? streakKey.value : this.streakKey,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AdhkarCategory copyWithCompanion(AdhkarCategoriesCompanion data) {
    return AdhkarCategory(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      featured: data.featured.present ? data.featured.value : this.featured,
      streakKey: data.streakKey.present ? data.streakKey.value : this.streakKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarCategory(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('featured: $featured, ')
          ..write('streakKey: $streakKey, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, featured, streakKey, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdhkarCategory &&
          other.id == this.id &&
          other.title == this.title &&
          other.featured == this.featured &&
          other.streakKey == this.streakKey &&
          other.sortOrder == this.sortOrder);
}

class AdhkarCategoriesCompanion extends UpdateCompanion<AdhkarCategory> {
  final Value<String> id;
  final Value<String> title;
  final Value<bool> featured;
  final Value<String?> streakKey;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AdhkarCategoriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.featured = const Value.absent(),
    this.streakKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdhkarCategoriesCompanion.insert({
    required String id,
    required String title,
    required bool featured,
    this.streakKey = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       featured = Value(featured),
       sortOrder = Value(sortOrder);
  static Insertable<AdhkarCategory> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<bool>? featured,
    Expression<String>? streakKey,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (featured != null) 'featured': featured,
      if (streakKey != null) 'streak_key': streakKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdhkarCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<bool>? featured,
    Value<String?>? streakKey,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AdhkarCategoriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      featured: featured ?? this.featured,
      streakKey: streakKey ?? this.streakKey,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (featured.present) {
      map['featured'] = Variable<bool>(featured.value);
    }
    if (streakKey.present) {
      map['streak_key'] = Variable<String>(streakKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('featured: $featured, ')
          ..write('streakKey: $streakKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdhkarItemsTable extends AdhkarItems
    with TableInfo<$AdhkarItemsTable, AdhkarItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdhkarItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES adhkar_categories (id)',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repeatCountMeta = const VerificationMeta(
    'repeatCount',
  );
  @override
  late final GeneratedColumn<int> repeatCount = GeneratedColumn<int>(
    'repeat_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    body,
    repeatCount,
    source,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adhkar_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdhkarItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('repeat_count')) {
      context.handle(
        _repeatCountMeta,
        repeatCount.isAcceptableOrUnknown(
          data['repeat_count']!,
          _repeatCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repeatCountMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdhkarItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdhkarItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      repeatCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_count'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AdhkarItemsTable createAlias(String alias) {
    return $AdhkarItemsTable(attachedDatabase, alias);
  }
}

class AdhkarItem extends DataClass implements Insertable<AdhkarItem> {
  final String id;
  final String categoryId;
  final String body;
  final int repeatCount;
  final String source;
  final int sortOrder;
  const AdhkarItem({
    required this.id,
    required this.categoryId,
    required this.body,
    required this.repeatCount,
    required this.source,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['body'] = Variable<String>(body);
    map['repeat_count'] = Variable<int>(repeatCount);
    map['source'] = Variable<String>(source);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AdhkarItemsCompanion toCompanion(bool nullToAbsent) {
    return AdhkarItemsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      body: Value(body),
      repeatCount: Value(repeatCount),
      source: Value(source),
      sortOrder: Value(sortOrder),
    );
  }

  factory AdhkarItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdhkarItem(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      body: serializer.fromJson<String>(json['body']),
      repeatCount: serializer.fromJson<int>(json['repeatCount']),
      source: serializer.fromJson<String>(json['source']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'body': serializer.toJson<String>(body),
      'repeatCount': serializer.toJson<int>(repeatCount),
      'source': serializer.toJson<String>(source),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AdhkarItem copyWith({
    String? id,
    String? categoryId,
    String? body,
    int? repeatCount,
    String? source,
    int? sortOrder,
  }) => AdhkarItem(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    body: body ?? this.body,
    repeatCount: repeatCount ?? this.repeatCount,
    source: source ?? this.source,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AdhkarItem copyWithCompanion(AdhkarItemsCompanion data) {
    return AdhkarItem(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      body: data.body.present ? data.body.value : this.body,
      repeatCount: data.repeatCount.present
          ? data.repeatCount.value
          : this.repeatCount,
      source: data.source.present ? data.source.value : this.source,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarItem(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('body: $body, ')
          ..write('repeatCount: $repeatCount, ')
          ..write('source: $source, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, categoryId, body, repeatCount, source, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdhkarItem &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.body == this.body &&
          other.repeatCount == this.repeatCount &&
          other.source == this.source &&
          other.sortOrder == this.sortOrder);
}

class AdhkarItemsCompanion extends UpdateCompanion<AdhkarItem> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String> body;
  final Value<int> repeatCount;
  final Value<String> source;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AdhkarItemsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.body = const Value.absent(),
    this.repeatCount = const Value.absent(),
    this.source = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdhkarItemsCompanion.insert({
    required String id,
    required String categoryId,
    required String body,
    required int repeatCount,
    required String source,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       body = Value(body),
       repeatCount = Value(repeatCount),
       source = Value(source),
       sortOrder = Value(sortOrder);
  static Insertable<AdhkarItem> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? body,
    Expression<int>? repeatCount,
    Expression<String>? source,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (body != null) 'body': body,
      if (repeatCount != null) 'repeat_count': repeatCount,
      if (source != null) 'source': source,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdhkarItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<String>? body,
    Value<int>? repeatCount,
    Value<String>? source,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AdhkarItemsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      body: body ?? this.body,
      repeatCount: repeatCount ?? this.repeatCount,
      source: source ?? this.source,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (repeatCount.present) {
      map['repeat_count'] = Variable<int>(repeatCount.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarItemsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('body: $body, ')
          ..write('repeatCount: $repeatCount, ')
          ..write('source: $source, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const Setting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Setting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      Setting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, surah, ayah, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final int id;
  final int surah;
  final int ayah;
  final DateTime createdAt;
  const Bookmark({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      surah: Value(surah),
      ayah: Value(ayah),
      createdAt: Value(createdAt),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<int>(json['id']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Bookmark copyWith({int? id, int? surah, int? ayah, DateTime? createdAt}) =>
      Bookmark(
        id: id ?? this.id,
        surah: surah ?? this.surah,
        ayah: ayah ?? this.ayah,
        createdAt: createdAt ?? this.createdAt,
      );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surah, ayah, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<int> id;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<DateTime> createdAt;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required int surah,
    required int ayah,
    required DateTime createdAt,
  }) : surah = Value(surah),
       ayah = Value(ayah),
       createdAt = Value(createdAt);
  static Insertable<Bookmark> custom({
    Expression<int>? id,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BookmarksCompanion copyWith({
    Value<int>? id,
    Value<int>? surah,
    Value<int>? ayah,
    Value<DateTime>? createdAt,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReaderStateTable extends ReaderState
    with TableInfo<$ReaderStateTable, ReaderStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReaderStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, surah, ayah, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reader_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReaderStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReaderStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReaderStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReaderStateTable createAlias(String alias) {
    return $ReaderStateTable(attachedDatabase, alias);
  }
}

class ReaderStateData extends DataClass implements Insertable<ReaderStateData> {
  final int id;
  final int surah;
  final int ayah;
  final DateTime updatedAt;
  const ReaderStateData({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReaderStateCompanion toCompanion(bool nullToAbsent) {
    return ReaderStateCompanion(
      id: Value(id),
      surah: Value(surah),
      ayah: Value(ayah),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReaderStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReaderStateData(
      id: serializer.fromJson<int>(json['id']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReaderStateData copyWith({
    int? id,
    int? surah,
    int? ayah,
    DateTime? updatedAt,
  }) => ReaderStateData(
    id: id ?? this.id,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReaderStateData copyWithCompanion(ReaderStateCompanion data) {
    return ReaderStateData(
      id: data.id.present ? data.id.value : this.id,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReaderStateData(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surah, ayah, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderStateData &&
          other.id == this.id &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.updatedAt == this.updatedAt);
}

class ReaderStateCompanion extends UpdateCompanion<ReaderStateData> {
  final Value<int> id;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<DateTime> updatedAt;
  const ReaderStateCompanion({
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ReaderStateCompanion.insert({
    this.id = const Value.absent(),
    required int surah,
    required int ayah,
    required DateTime updatedAt,
  }) : surah = Value(surah),
       ayah = Value(ayah),
       updatedAt = Value(updatedAt);
  static Insertable<ReaderStateData> custom({
    Expression<int>? id,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ReaderStateCompanion copyWith({
    Value<int>? id,
    Value<int>? surah,
    Value<int>? ayah,
    Value<DateTime>? updatedAt,
  }) {
    return ReaderStateCompanion(
      id: id ?? this.id,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReaderStateCompanion(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AdhkarProgressTable extends AdhkarProgress
    with TableInfo<$AdhkarProgressTable, AdhkarProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdhkarProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedCountMeta = const VerificationMeta(
    'completedCount',
  );
  @override
  late final GeneratedColumn<int> completedCount = GeneratedColumn<int>(
    'completed_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, completedCount, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adhkar_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdhkarProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('completed_count')) {
      context.handle(
        _completedCountMeta,
        completedCount.isAcceptableOrUnknown(
          data['completed_count']!,
          _completedCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedCountMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  AdhkarProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdhkarProgressData(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      completedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_count'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AdhkarProgressTable createAlias(String alias) {
    return $AdhkarProgressTable(attachedDatabase, alias);
  }
}

class AdhkarProgressData extends DataClass
    implements Insertable<AdhkarProgressData> {
  final String itemId;
  final int completedCount;
  final DateTime updatedAt;
  const AdhkarProgressData({
    required this.itemId,
    required this.completedCount,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['completed_count'] = Variable<int>(completedCount);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AdhkarProgressCompanion toCompanion(bool nullToAbsent) {
    return AdhkarProgressCompanion(
      itemId: Value(itemId),
      completedCount: Value(completedCount),
      updatedAt: Value(updatedAt),
    );
  }

  factory AdhkarProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdhkarProgressData(
      itemId: serializer.fromJson<String>(json['itemId']),
      completedCount: serializer.fromJson<int>(json['completedCount']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'completedCount': serializer.toJson<int>(completedCount),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AdhkarProgressData copyWith({
    String? itemId,
    int? completedCount,
    DateTime? updatedAt,
  }) => AdhkarProgressData(
    itemId: itemId ?? this.itemId,
    completedCount: completedCount ?? this.completedCount,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AdhkarProgressData copyWithCompanion(AdhkarProgressCompanion data) {
    return AdhkarProgressData(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      completedCount: data.completedCount.present
          ? data.completedCount.value
          : this.completedCount,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarProgressData(')
          ..write('itemId: $itemId, ')
          ..write('completedCount: $completedCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, completedCount, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdhkarProgressData &&
          other.itemId == this.itemId &&
          other.completedCount == this.completedCount &&
          other.updatedAt == this.updatedAt);
}

class AdhkarProgressCompanion extends UpdateCompanion<AdhkarProgressData> {
  final Value<String> itemId;
  final Value<int> completedCount;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AdhkarProgressCompanion({
    this.itemId = const Value.absent(),
    this.completedCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdhkarProgressCompanion.insert({
    required String itemId,
    required int completedCount,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       completedCount = Value(completedCount),
       updatedAt = Value(updatedAt);
  static Insertable<AdhkarProgressData> custom({
    Expression<String>? itemId,
    Expression<int>? completedCount,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (completedCount != null) 'completed_count': completedCount,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdhkarProgressCompanion copyWith({
    Value<String>? itemId,
    Value<int>? completedCount,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AdhkarProgressCompanion(
      itemId: itemId ?? this.itemId,
      completedCount: completedCount ?? this.completedCount,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (completedCount.present) {
      map['completed_count'] = Variable<int>(completedCount.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarProgressCompanion(')
          ..write('itemId: $itemId, ')
          ..write('completedCount: $completedCount, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdhkarLogsTable extends AdhkarLogs
    with TableInfo<$AdhkarLogsTable, AdhkarLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdhkarLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _streakKeyMeta = const VerificationMeta(
    'streakKey',
  );
  @override
  late final GeneratedColumn<String> streakKey = GeneratedColumn<String>(
    'streak_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, streakKey, localDate, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adhkar_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdhkarLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('streak_key')) {
      context.handle(
        _streakKeyMeta,
        streakKey.isAcceptableOrUnknown(data['streak_key']!, _streakKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_streakKeyMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdhkarLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdhkarLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      streakKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}streak_key'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $AdhkarLogsTable createAlias(String alias) {
    return $AdhkarLogsTable(attachedDatabase, alias);
  }
}

class AdhkarLog extends DataClass implements Insertable<AdhkarLog> {
  final int id;
  final String streakKey;
  final String localDate;
  final DateTime completedAt;
  const AdhkarLog({
    required this.id,
    required this.streakKey,
    required this.localDate,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['streak_key'] = Variable<String>(streakKey);
    map['local_date'] = Variable<String>(localDate);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  AdhkarLogsCompanion toCompanion(bool nullToAbsent) {
    return AdhkarLogsCompanion(
      id: Value(id),
      streakKey: Value(streakKey),
      localDate: Value(localDate),
      completedAt: Value(completedAt),
    );
  }

  factory AdhkarLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdhkarLog(
      id: serializer.fromJson<int>(json['id']),
      streakKey: serializer.fromJson<String>(json['streakKey']),
      localDate: serializer.fromJson<String>(json['localDate']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'streakKey': serializer.toJson<String>(streakKey),
      'localDate': serializer.toJson<String>(localDate),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  AdhkarLog copyWith({
    int? id,
    String? streakKey,
    String? localDate,
    DateTime? completedAt,
  }) => AdhkarLog(
    id: id ?? this.id,
    streakKey: streakKey ?? this.streakKey,
    localDate: localDate ?? this.localDate,
    completedAt: completedAt ?? this.completedAt,
  );
  AdhkarLog copyWithCompanion(AdhkarLogsCompanion data) {
    return AdhkarLog(
      id: data.id.present ? data.id.value : this.id,
      streakKey: data.streakKey.present ? data.streakKey.value : this.streakKey,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarLog(')
          ..write('id: $id, ')
          ..write('streakKey: $streakKey, ')
          ..write('localDate: $localDate, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, streakKey, localDate, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdhkarLog &&
          other.id == this.id &&
          other.streakKey == this.streakKey &&
          other.localDate == this.localDate &&
          other.completedAt == this.completedAt);
}

class AdhkarLogsCompanion extends UpdateCompanion<AdhkarLog> {
  final Value<int> id;
  final Value<String> streakKey;
  final Value<String> localDate;
  final Value<DateTime> completedAt;
  const AdhkarLogsCompanion({
    this.id = const Value.absent(),
    this.streakKey = const Value.absent(),
    this.localDate = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  AdhkarLogsCompanion.insert({
    this.id = const Value.absent(),
    required String streakKey,
    this.localDate = const Value.absent(),
    required DateTime completedAt,
  }) : streakKey = Value(streakKey),
       completedAt = Value(completedAt);
  static Insertable<AdhkarLog> custom({
    Expression<int>? id,
    Expression<String>? streakKey,
    Expression<String>? localDate,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (streakKey != null) 'streak_key': streakKey,
      if (localDate != null) 'local_date': localDate,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  AdhkarLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? streakKey,
    Value<String>? localDate,
    Value<DateTime>? completedAt,
  }) {
    return AdhkarLogsCompanion(
      id: id ?? this.id,
      streakKey: streakKey ?? this.streakKey,
      localDate: localDate ?? this.localDate,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (streakKey.present) {
      map['streak_key'] = Variable<String>(streakKey.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdhkarLogsCompanion(')
          ..write('id: $id, ')
          ..write('streakKey: $streakKey, ')
          ..write('localDate: $localDate, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $PrayerLogsTable extends PrayerLogs
    with TableInfo<$PrayerLogsTable, PrayerLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prayerMeta = const VerificationMeta('prayer');
  @override
  late final GeneratedColumn<String> prayer = GeneratedColumn<String>(
    'prayer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, prayer, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrayerLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('prayer')) {
      context.handle(
        _prayerMeta,
        prayer.isAcceptableOrUnknown(data['prayer']!, _prayerMeta),
      );
    } else if (isInserting) {
      context.missing(_prayerMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, prayer};
  @override
  PrayerLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerLog(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      prayer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prayer'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $PrayerLogsTable createAlias(String alias) {
    return $PrayerLogsTable(attachedDatabase, alias);
  }
}

class PrayerLog extends DataClass implements Insertable<PrayerLog> {
  final String date;
  final String prayer;
  final String status;
  const PrayerLog({
    required this.date,
    required this.prayer,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['prayer'] = Variable<String>(prayer);
    map['status'] = Variable<String>(status);
    return map;
  }

  PrayerLogsCompanion toCompanion(bool nullToAbsent) {
    return PrayerLogsCompanion(
      date: Value(date),
      prayer: Value(prayer),
      status: Value(status),
    );
  }

  factory PrayerLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerLog(
      date: serializer.fromJson<String>(json['date']),
      prayer: serializer.fromJson<String>(json['prayer']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'prayer': serializer.toJson<String>(prayer),
      'status': serializer.toJson<String>(status),
    };
  }

  PrayerLog copyWith({String? date, String? prayer, String? status}) =>
      PrayerLog(
        date: date ?? this.date,
        prayer: prayer ?? this.prayer,
        status: status ?? this.status,
      );
  PrayerLog copyWithCompanion(PrayerLogsCompanion data) {
    return PrayerLog(
      date: data.date.present ? data.date.value : this.date,
      prayer: data.prayer.present ? data.prayer.value : this.prayer,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerLog(')
          ..write('date: $date, ')
          ..write('prayer: $prayer, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, prayer, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerLog &&
          other.date == this.date &&
          other.prayer == this.prayer &&
          other.status == this.status);
}

class PrayerLogsCompanion extends UpdateCompanion<PrayerLog> {
  final Value<String> date;
  final Value<String> prayer;
  final Value<String> status;
  final Value<int> rowid;
  const PrayerLogsCompanion({
    this.date = const Value.absent(),
    this.prayer = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrayerLogsCompanion.insert({
    required String date,
    required String prayer,
    required String status,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       prayer = Value(prayer),
       status = Value(status);
  static Insertable<PrayerLog> custom({
    Expression<String>? date,
    Expression<String>? prayer,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (prayer != null) 'prayer': prayer,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrayerLogsCompanion copyWith({
    Value<String>? date,
    Value<String>? prayer,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return PrayerLogsCompanion(
      date: date ?? this.date,
      prayer: prayer ?? this.prayer,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (prayer.present) {
      map['prayer'] = Variable<String>(prayer.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerLogsCompanion(')
          ..write('date: $date, ')
          ..write('prayer: $prayer, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SurahsTable surahs = $SurahsTable(this);
  late final $AyahsTable ayahs = $AyahsTable(this);
  late final $JuzsTable juzs = $JuzsTable(this);
  late final $QuranPagesTable quranPages = $QuranPagesTable(this);
  late final $AdhkarCategoriesTable adhkarCategories = $AdhkarCategoriesTable(
    this,
  );
  late final $AdhkarItemsTable adhkarItems = $AdhkarItemsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $ReaderStateTable readerState = $ReaderStateTable(this);
  late final $AdhkarProgressTable adhkarProgress = $AdhkarProgressTable(this);
  late final $AdhkarLogsTable adhkarLogs = $AdhkarLogsTable(this);
  late final $PrayerLogsTable prayerLogs = $PrayerLogsTable(this);
  late final Index ayahsJuz = Index(
    'ayahs_juz',
    'CREATE INDEX ayahs_juz ON ayahs (juz)',
  );
  late final Index ayahsPage = Index(
    'ayahs_page',
    'CREATE INDEX ayahs_page ON ayahs (page)',
  );
  late final Index adhkarItemsCategory = Index(
    'adhkar_items_category',
    'CREATE INDEX adhkar_items_category ON adhkar_items (category_id)',
  );
  late final Index bookmarksAyah = Index(
    'bookmarks_ayah',
    'CREATE UNIQUE INDEX bookmarks_ayah ON bookmarks (surah, ayah)',
  );
  late final Index adhkarLogsStreak = Index(
    'adhkar_logs_streak',
    'CREATE INDEX adhkar_logs_streak ON adhkar_logs (streak_key, local_date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    surahs,
    ayahs,
    juzs,
    quranPages,
    adhkarCategories,
    adhkarItems,
    settings,
    bookmarks,
    readerState,
    adhkarProgress,
    adhkarLogs,
    prayerLogs,
    ayahsJuz,
    ayahsPage,
    adhkarItemsCategory,
    bookmarksAyah,
    adhkarLogsStreak,
  ];
}

typedef $$SurahsTableCreateCompanionBuilder = SurahsCompanion Function({
  Value<int> number,
  required String name,
  required String englishName,
  required String meaning,
  required int ayahCount,
  required String revelation,
  Value<String?> bismillah,
});
typedef $$SurahsTableUpdateCompanionBuilder = SurahsCompanion Function({
  Value<int> number,
  Value<String> name,
  Value<String> englishName,
  Value<String> meaning,
  Value<int> ayahCount,
  Value<String> revelation,
  Value<String?> bismillah,
});

final class $$SurahsTableReferences
    extends BaseReferences<_$AppDatabase, $SurahsTable, Surah> {
  $$SurahsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AyahsTable, List<Ayah>> _ayahsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ayahs,
    aliasName: 'surahs__number__ayahs__surah',
  );

  $$AyahsTableProcessedTableManager get ayahsRefs {
    final manager = $$AyahsTableTableManager(
      $_db,
      $_db.ayahs,
    ).filter((f) => f.surah.number.sqlEquals($_itemColumn<int>('number')!));

    final cache = $_typedResult.readTableOrNull(_ayahsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JuzsTable, List<Juz>> _juzsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.juzs,
    aliasName: 'surahs__number__juzs__surah',
  );

  $$JuzsTableProcessedTableManager get juzsRefs {
    final manager = $$JuzsTableTableManager(
      $_db,
      $_db.juzs,
    ).filter((f) => f.surah.number.sqlEquals($_itemColumn<int>('number')!));

    final cache = $_typedResult.readTableOrNull(_juzsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QuranPagesTable, List<QuranPage>>
  _quranPagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.quranPages,
    aliasName: 'surahs__number__quran_pages__surah',
  );

  $$QuranPagesTableProcessedTableManager get quranPagesRefs {
    final manager = $$QuranPagesTableTableManager(
      $_db,
      $_db.quranPages,
    ).filter((f) => f.surah.number.sqlEquals($_itemColumn<int>('number')!));

    final cache = $_typedResult.readTableOrNull(_quranPagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SurahsTableFilterComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revelation => $composableBuilder(
    column: $table.revelation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bismillah => $composableBuilder(
    column: $table.bismillah,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ayahsRefs(
    Expression<bool> Function($$AyahsTableFilterComposer f) f,
  ) {
    final $$AyahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.number,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.surah,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableFilterComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> juzsRefs(
    Expression<bool> Function($$JuzsTableFilterComposer f) f,
  ) {
    final $$JuzsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.number,
      referencedTable: $db.juzs,
      getReferencedColumn: (t) => t.surah,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JuzsTableFilterComposer(
            $db: $db,
            $table: $db.juzs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> quranPagesRefs(
    Expression<bool> Function($$QuranPagesTableFilterComposer f) f,
  ) {
    final $$QuranPagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.number,
      referencedTable: $db.quranPages,
      getReferencedColumn: (t) => t.surah,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuranPagesTableFilterComposer(
            $db: $db,
            $table: $db.quranPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SurahsTableOrderingComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revelation => $composableBuilder(
    column: $table.revelation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bismillah => $composableBuilder(
    column: $table.bismillah,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SurahsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<int> get ayahCount =>
      $composableBuilder(column: $table.ayahCount, builder: (column) => column);

  GeneratedColumn<String> get revelation => $composableBuilder(
    column: $table.revelation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bismillah =>
      $composableBuilder(column: $table.bismillah, builder: (column) => column);

  Expression<T> ayahsRefs<T extends Object>(
    Expression<T> Function($$AyahsTableAnnotationComposer a) f,
  ) {
    final $$AyahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.number,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.surah,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableAnnotationComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> juzsRefs<T extends Object>(
    Expression<T> Function($$JuzsTableAnnotationComposer a) f,
  ) {
    final $$JuzsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.number,
      referencedTable: $db.juzs,
      getReferencedColumn: (t) => t.surah,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JuzsTableAnnotationComposer(
            $db: $db,
            $table: $db.juzs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> quranPagesRefs<T extends Object>(
    Expression<T> Function($$QuranPagesTableAnnotationComposer a) f,
  ) {
    final $$QuranPagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.number,
      referencedTable: $db.quranPages,
      getReferencedColumn: (t) => t.surah,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuranPagesTableAnnotationComposer(
            $db: $db,
            $table: $db.quranPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SurahsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SurahsTable,
          Surah,
          $$SurahsTableFilterComposer,
          $$SurahsTableOrderingComposer,
          $$SurahsTableAnnotationComposer,
          $$SurahsTableCreateCompanionBuilder,
          $$SurahsTableUpdateCompanionBuilder,
          (Surah, $$SurahsTableReferences),
          Surah,
          PrefetchHooks Function({
            bool ayahsRefs,
            bool juzsRefs,
            bool quranPagesRefs,
          })
        > {
  $$SurahsTableTableManager(_$AppDatabase db, $SurahsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> englishName = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<int> ayahCount = const Value.absent(),
                Value<String> revelation = const Value.absent(),
                Value<String?> bismillah = const Value.absent(),
              }) => SurahsCompanion(
                number: number,
                name: name,
                englishName: englishName,
                meaning: meaning,
                ayahCount: ayahCount,
                revelation: revelation,
                bismillah: bismillah,
              ),
          createCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                required String name,
                required String englishName,
                required String meaning,
                required int ayahCount,
                required String revelation,
                Value<String?> bismillah = const Value.absent(),
              }) => SurahsCompanion.insert(
                number: number,
                name: name,
                englishName: englishName,
                meaning: meaning,
                ayahCount: ayahCount,
                revelation: revelation,
                bismillah: bismillah,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SurahsTable, Surah>(table),
                  $$SurahsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({ayahsRefs = false, juzsRefs = false, quranPagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ayahsRefs) db.ayahs,
                    if (juzsRefs) db.juzs,
                    if (quranPagesRefs) db.quranPages,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ayahsRefs)
                        await $_getPrefetchedDataByColumns<
                          Surah,
                          $SurahsTable,
                          Ayah,
                          $AyahsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SurahsTableReferences
                              ._ayahsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SurahsTableReferences(db, table, p0).ayahsRefs,
                          currentColumn: 'number',
                          referencedColumn: 'surah',
                          typedResults: items,
                        ),
                      if (juzsRefs)
                        await $_getPrefetchedDataByColumns<
                          Surah,
                          $SurahsTable,
                          Juz,
                          $JuzsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SurahsTableReferences
                              ._juzsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SurahsTableReferences(db, table, p0).juzsRefs,
                          currentColumn: 'number',
                          referencedColumn: 'surah',
                          typedResults: items,
                        ),
                      if (quranPagesRefs)
                        await $_getPrefetchedDataByColumns<
                          Surah,
                          $SurahsTable,
                          QuranPage,
                          $QuranPagesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SurahsTableReferences
                              ._quranPagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SurahsTableReferences(
                                db,
                                table,
                                p0,
                              ).quranPagesRefs,
                          currentColumn: 'number',
                          referencedColumn: 'surah',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SurahsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SurahsTable,
      Surah,
      $$SurahsTableFilterComposer,
      $$SurahsTableOrderingComposer,
      $$SurahsTableAnnotationComposer,
      $$SurahsTableCreateCompanionBuilder,
      $$SurahsTableUpdateCompanionBuilder,
      (Surah, $$SurahsTableReferences),
      Surah,
      PrefetchHooks Function({
        bool ayahsRefs,
        bool juzsRefs,
        bool quranPagesRefs,
      })
    >;
typedef $$AyahsTableCreateCompanionBuilder = AyahsCompanion Function({
  required int surah,
  required int ayah,
  required String body,
  required int juz,
  required int page,
  Value<bool> sajda,
  Value<int> rowid,
});
typedef $$AyahsTableUpdateCompanionBuilder = AyahsCompanion Function({
  Value<int> surah,
  Value<int> ayah,
  Value<String> body,
  Value<int> juz,
  Value<int> page,
  Value<bool> sajda,
  Value<int> rowid,
});

final class $$AyahsTableReferences
    extends BaseReferences<_$AppDatabase, $AyahsTable, Ayah> {
  $$AyahsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SurahsTable _surahTable(_$AppDatabase db) =>
      db.surahs.createAlias('ayahs__surah__surahs__number');

  $$SurahsTableProcessedTableManager get surah {
    final $_column = $_itemColumn<int>('surah')!;

    final manager = $$SurahsTableTableManager(
      $_db,
      $_db.surahs,
    ).filter((f) => f.number.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surahTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AyahsTableFilterComposer extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get juz => $composableBuilder(
    column: $table.juz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sajda => $composableBuilder(
    column: $table.sajda,
    builder: (column) => ColumnFilters(column),
  );

  $$SurahsTableFilterComposer get surah {
    final $$SurahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableFilterComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AyahsTableOrderingComposer
    extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get juz => $composableBuilder(
    column: $table.juz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sajda => $composableBuilder(
    column: $table.sajda,
    builder: (column) => ColumnOrderings(column),
  );

  $$SurahsTableOrderingComposer get surah {
    final $$SurahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableOrderingComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AyahsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get juz =>
      $composableBuilder(column: $table.juz, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<bool> get sajda =>
      $composableBuilder(column: $table.sajda, builder: (column) => column);

  $$SurahsTableAnnotationComposer get surah {
    final $$SurahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableAnnotationComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AyahsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AyahsTable,
          Ayah,
          $$AyahsTableFilterComposer,
          $$AyahsTableOrderingComposer,
          $$AyahsTableAnnotationComposer,
          $$AyahsTableCreateCompanionBuilder,
          $$AyahsTableUpdateCompanionBuilder,
          (Ayah, $$AyahsTableReferences),
          Ayah,
          PrefetchHooks Function({bool surah})
        > {
  $$AyahsTableTableManager(_$AppDatabase db, $AyahsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> juz = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<bool> sajda = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AyahsCompanion(
                surah: surah,
                ayah: ayah,
                body: body,
                juz: juz,
                page: page,
                sajda: sajda,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int surah,
                required int ayah,
                required String body,
                required int juz,
                required int page,
                Value<bool> sajda = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AyahsCompanion.insert(
                surah: surah,
                ayah: ayah,
                body: body,
                juz: juz,
                page: page,
                sajda: sajda,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AyahsTable, Ayah>(table),
                  $$AyahsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({surah = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (surah) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.surah,
                        referencedTable: $$AyahsTableReferences._surahTable(db),
                        referencedColumn: $$AyahsTableReferences
                            ._surahTable(db)
                            .number,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AyahsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AyahsTable,
      Ayah,
      $$AyahsTableFilterComposer,
      $$AyahsTableOrderingComposer,
      $$AyahsTableAnnotationComposer,
      $$AyahsTableCreateCompanionBuilder,
      $$AyahsTableUpdateCompanionBuilder,
      (Ayah, $$AyahsTableReferences),
      Ayah,
      PrefetchHooks Function({bool surah})
    >;
typedef $$JuzsTableCreateCompanionBuilder = JuzsCompanion Function({
  Value<int> number,
  required int surah,
  required int ayah,
  required int ayahCount,
});
typedef $$JuzsTableUpdateCompanionBuilder = JuzsCompanion Function({
  Value<int> number,
  Value<int> surah,
  Value<int> ayah,
  Value<int> ayahCount,
});

final class $$JuzsTableReferences
    extends BaseReferences<_$AppDatabase, $JuzsTable, Juz> {
  $$JuzsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SurahsTable _surahTable(_$AppDatabase db) =>
      db.surahs.createAlias('juzs__surah__surahs__number');

  $$SurahsTableProcessedTableManager get surah {
    final $_column = $_itemColumn<int>('surah')!;

    final manager = $$SurahsTableTableManager(
      $_db,
      $_db.surahs,
    ).filter((f) => f.number.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surahTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JuzsTableFilterComposer extends Composer<_$AppDatabase, $JuzsTable> {
  $$JuzsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnFilters(column),
  );

  $$SurahsTableFilterComposer get surah {
    final $$SurahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableFilterComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JuzsTableOrderingComposer extends Composer<_$AppDatabase, $JuzsTable> {
  $$JuzsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$SurahsTableOrderingComposer get surah {
    final $$SurahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableOrderingComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JuzsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JuzsTable> {
  $$JuzsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get ayahCount =>
      $composableBuilder(column: $table.ayahCount, builder: (column) => column);

  $$SurahsTableAnnotationComposer get surah {
    final $$SurahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableAnnotationComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JuzsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JuzsTable,
          Juz,
          $$JuzsTableFilterComposer,
          $$JuzsTableOrderingComposer,
          $$JuzsTableAnnotationComposer,
          $$JuzsTableCreateCompanionBuilder,
          $$JuzsTableUpdateCompanionBuilder,
          (Juz, $$JuzsTableReferences),
          Juz,
          PrefetchHooks Function({bool surah})
        > {
  $$JuzsTableTableManager(_$AppDatabase db, $JuzsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JuzsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JuzsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JuzsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> ayahCount = const Value.absent(),
              }) => JuzsCompanion(
                number: number,
                surah: surah,
                ayah: ayah,
                ayahCount: ayahCount,
              ),
          createCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                required int surah,
                required int ayah,
                required int ayahCount,
              }) => JuzsCompanion.insert(
                number: number,
                surah: surah,
                ayah: ayah,
                ayahCount: ayahCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JuzsTable, Juz>(table),
                  $$JuzsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({surah = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (surah) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.surah,
                        referencedTable: $$JuzsTableReferences._surahTable(db),
                        referencedColumn: $$JuzsTableReferences
                            ._surahTable(db)
                            .number,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$JuzsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JuzsTable,
      Juz,
      $$JuzsTableFilterComposer,
      $$JuzsTableOrderingComposer,
      $$JuzsTableAnnotationComposer,
      $$JuzsTableCreateCompanionBuilder,
      $$JuzsTableUpdateCompanionBuilder,
      (Juz, $$JuzsTableReferences),
      Juz,
      PrefetchHooks Function({bool surah})
    >;
typedef $$QuranPagesTableCreateCompanionBuilder = QuranPagesCompanion Function({
  Value<int> number,
  required int surah,
  required int ayah,
});
typedef $$QuranPagesTableUpdateCompanionBuilder = QuranPagesCompanion Function({
  Value<int> number,
  Value<int> surah,
  Value<int> ayah,
});

final class $$QuranPagesTableReferences
    extends BaseReferences<_$AppDatabase, $QuranPagesTable, QuranPage> {
  $$QuranPagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SurahsTable _surahTable(_$AppDatabase db) =>
      db.surahs.createAlias('quran_pages__surah__surahs__number');

  $$SurahsTableProcessedTableManager get surah {
    final $_column = $_itemColumn<int>('surah')!;

    final manager = $$SurahsTableTableManager(
      $_db,
      $_db.surahs,
    ).filter((f) => f.number.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surahTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuranPagesTableFilterComposer
    extends Composer<_$AppDatabase, $QuranPagesTable> {
  $$QuranPagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  $$SurahsTableFilterComposer get surah {
    final $$SurahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableFilterComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuranPagesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuranPagesTable> {
  $$QuranPagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  $$SurahsTableOrderingComposer get surah {
    final $$SurahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableOrderingComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuranPagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuranPagesTable> {
  $$QuranPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  $$SurahsTableAnnotationComposer get surah {
    final $$SurahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableAnnotationComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuranPagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuranPagesTable,
          QuranPage,
          $$QuranPagesTableFilterComposer,
          $$QuranPagesTableOrderingComposer,
          $$QuranPagesTableAnnotationComposer,
          $$QuranPagesTableCreateCompanionBuilder,
          $$QuranPagesTableUpdateCompanionBuilder,
          (QuranPage, $$QuranPagesTableReferences),
          QuranPage,
          PrefetchHooks Function({bool surah})
        > {
  $$QuranPagesTableTableManager(_$AppDatabase db, $QuranPagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuranPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuranPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuranPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> number = const Value.absent(),
            Value<int> surah = const Value.absent(),
            Value<int> ayah = const Value.absent(),
          }) => QuranPagesCompanion(number: number, surah: surah, ayah: ayah),
          createCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                required int surah,
                required int ayah,
              }) => QuranPagesCompanion.insert(
                number: number,
                surah: surah,
                ayah: ayah,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuranPagesTable, QuranPage>(table),
                  $$QuranPagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({surah = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (surah) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.surah,
                        referencedTable: $$QuranPagesTableReferences
                            ._surahTable(db),
                        referencedColumn: $$QuranPagesTableReferences
                            ._surahTable(db)
                            .number,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QuranPagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuranPagesTable,
      QuranPage,
      $$QuranPagesTableFilterComposer,
      $$QuranPagesTableOrderingComposer,
      $$QuranPagesTableAnnotationComposer,
      $$QuranPagesTableCreateCompanionBuilder,
      $$QuranPagesTableUpdateCompanionBuilder,
      (QuranPage, $$QuranPagesTableReferences),
      QuranPage,
      PrefetchHooks Function({bool surah})
    >;
typedef $$AdhkarCategoriesTableCreateCompanionBuilder =
    AdhkarCategoriesCompanion Function({
      required String id,
      required String title,
      required bool featured,
      Value<String?> streakKey,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$AdhkarCategoriesTableUpdateCompanionBuilder =
    AdhkarCategoriesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<bool> featured,
      Value<String?> streakKey,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$AdhkarCategoriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $AdhkarCategoriesTable, AdhkarCategory> {
  $$AdhkarCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$AdhkarItemsTable, List<AdhkarItem>>
  _adhkarItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.adhkarItems,
    aliasName: 'adhkar_categories__id__adhkar_items__category_id',
  );

  $$AdhkarItemsTableProcessedTableManager get adhkarItemsRefs {
    final manager = $$AdhkarItemsTableTableManager(
      $_db,
      $_db.adhkarItems,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_adhkarItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AdhkarCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $AdhkarCategoriesTable> {
  $$AdhkarCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get featured => $composableBuilder(
    column: $table.featured,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streakKey => $composableBuilder(
    column: $table.streakKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> adhkarItemsRefs(
    Expression<bool> Function($$AdhkarItemsTableFilterComposer f) f,
  ) {
    final $$AdhkarItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adhkarItems,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdhkarItemsTableFilterComposer(
            $db: $db,
            $table: $db.adhkarItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AdhkarCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AdhkarCategoriesTable> {
  $$AdhkarCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get featured => $composableBuilder(
    column: $table.featured,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streakKey => $composableBuilder(
    column: $table.streakKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdhkarCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdhkarCategoriesTable> {
  $$AdhkarCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get featured =>
      $composableBuilder(column: $table.featured, builder: (column) => column);

  GeneratedColumn<String> get streakKey =>
      $composableBuilder(column: $table.streakKey, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> adhkarItemsRefs<T extends Object>(
    Expression<T> Function($$AdhkarItemsTableAnnotationComposer a) f,
  ) {
    final $$AdhkarItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adhkarItems,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdhkarItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.adhkarItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AdhkarCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdhkarCategoriesTable,
          AdhkarCategory,
          $$AdhkarCategoriesTableFilterComposer,
          $$AdhkarCategoriesTableOrderingComposer,
          $$AdhkarCategoriesTableAnnotationComposer,
          $$AdhkarCategoriesTableCreateCompanionBuilder,
          $$AdhkarCategoriesTableUpdateCompanionBuilder,
          (AdhkarCategory, $$AdhkarCategoriesTableReferences),
          AdhkarCategory,
          PrefetchHooks Function({bool adhkarItemsRefs})
        > {
  $$AdhkarCategoriesTableTableManager(
    _$AppDatabase db,
    $AdhkarCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdhkarCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdhkarCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdhkarCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> featured = const Value.absent(),
                Value<String?> streakKey = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhkarCategoriesCompanion(
                id: id,
                title: title,
                featured: featured,
                streakKey: streakKey,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required bool featured,
                Value<String?> streakKey = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => AdhkarCategoriesCompanion.insert(
                id: id,
                title: title,
                featured: featured,
                streakKey: streakKey,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AdhkarCategoriesTable, AdhkarCategory>(table),
                  $$AdhkarCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({adhkarItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (adhkarItemsRefs) db.adhkarItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (adhkarItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      AdhkarCategory,
                      $AdhkarCategoriesTable,
                      AdhkarItem,
                      $AdhkarItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$AdhkarCategoriesTableReferences
                          ._adhkarItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AdhkarCategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).adhkarItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'category_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AdhkarCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdhkarCategoriesTable,
      AdhkarCategory,
      $$AdhkarCategoriesTableFilterComposer,
      $$AdhkarCategoriesTableOrderingComposer,
      $$AdhkarCategoriesTableAnnotationComposer,
      $$AdhkarCategoriesTableCreateCompanionBuilder,
      $$AdhkarCategoriesTableUpdateCompanionBuilder,
      (AdhkarCategory, $$AdhkarCategoriesTableReferences),
      AdhkarCategory,
      PrefetchHooks Function({bool adhkarItemsRefs})
    >;
typedef $$AdhkarItemsTableCreateCompanionBuilder =
    AdhkarItemsCompanion Function({
      required String id,
      required String categoryId,
      required String body,
      required int repeatCount,
      required String source,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$AdhkarItemsTableUpdateCompanionBuilder =
    AdhkarItemsCompanion Function({
      Value<String> id,
      Value<String> categoryId,
      Value<String> body,
      Value<int> repeatCount,
      Value<String> source,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$AdhkarItemsTableReferences
    extends BaseReferences<_$AppDatabase, $AdhkarItemsTable, AdhkarItem> {
  $$AdhkarItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AdhkarCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .adhkarCategories
      .createAlias('adhkar_items__category_id__adhkar_categories__id');

  $$AdhkarCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$AdhkarCategoriesTableTableManager(
      $_db,
      $_db.adhkarCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AdhkarItemsTableFilterComposer
    extends Composer<_$AppDatabase, $AdhkarItemsTable> {
  $$AdhkarItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatCount => $composableBuilder(
    column: $table.repeatCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$AdhkarCategoriesTableFilterComposer get categoryId {
    final $$AdhkarCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.adhkarCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdhkarCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.adhkarCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdhkarItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $AdhkarItemsTable> {
  $$AdhkarItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatCount => $composableBuilder(
    column: $table.repeatCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$AdhkarCategoriesTableOrderingComposer get categoryId {
    final $$AdhkarCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.adhkarCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdhkarCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.adhkarCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdhkarItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdhkarItemsTable> {
  $$AdhkarItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get repeatCount => $composableBuilder(
    column: $table.repeatCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$AdhkarCategoriesTableAnnotationComposer get categoryId {
    final $$AdhkarCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.adhkarCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdhkarCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.adhkarCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdhkarItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdhkarItemsTable,
          AdhkarItem,
          $$AdhkarItemsTableFilterComposer,
          $$AdhkarItemsTableOrderingComposer,
          $$AdhkarItemsTableAnnotationComposer,
          $$AdhkarItemsTableCreateCompanionBuilder,
          $$AdhkarItemsTableUpdateCompanionBuilder,
          (AdhkarItem, $$AdhkarItemsTableReferences),
          AdhkarItem,
          PrefetchHooks Function({bool categoryId})
        > {
  $$AdhkarItemsTableTableManager(_$AppDatabase db, $AdhkarItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdhkarItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdhkarItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdhkarItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> repeatCount = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhkarItemsCompanion(
                id: id,
                categoryId: categoryId,
                body: body,
                repeatCount: repeatCount,
                source: source,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                required String body,
                required int repeatCount,
                required String source,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => AdhkarItemsCompanion.insert(
                id: id,
                categoryId: categoryId,
                body: body,
                repeatCount: repeatCount,
                source: source,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AdhkarItemsTable, AdhkarItem>(table),
                  $$AdhkarItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$AdhkarItemsTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$AdhkarItemsTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AdhkarItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdhkarItemsTable,
      AdhkarItem,
      $$AdhkarItemsTableFilterComposer,
      $$AdhkarItemsTableOrderingComposer,
      $$AdhkarItemsTableAnnotationComposer,
      $$AdhkarItemsTableCreateCompanionBuilder,
      $$AdhkarItemsTableUpdateCompanionBuilder,
      (AdhkarItem, $$AdhkarItemsTableReferences),
      AdhkarItem,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$BookmarksTableCreateCompanionBuilder = BookmarksCompanion Function({
  Value<int> id,
  required int surah,
  required int ayah,
  required DateTime createdAt,
});
typedef $$BookmarksTableUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<int> id,
  Value<int> surah,
  Value<int> ayah,
  Value<DateTime> createdAt,
});

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
          Bookmark,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                surah: surah,
                ayah: ayah,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surah,
                required int ayah,
                required DateTime createdAt,
              }) => BookmarksCompanion.insert(
                id: id,
                surah: surah,
                ayah: ayah,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookmarksTable, Bookmark>(table),
                  BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
      Bookmark,
      PrefetchHooks Function()
    >;
typedef $$ReaderStateTableCreateCompanionBuilder =
    ReaderStateCompanion Function({
      Value<int> id,
      required int surah,
      required int ayah,
      required DateTime updatedAt,
    });
typedef $$ReaderStateTableUpdateCompanionBuilder =
    ReaderStateCompanion Function({
      Value<int> id,
      Value<int> surah,
      Value<int> ayah,
      Value<DateTime> updatedAt,
    });

class $$ReaderStateTableFilterComposer
    extends Composer<_$AppDatabase, $ReaderStateTable> {
  $$ReaderStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReaderStateTableOrderingComposer
    extends Composer<_$AppDatabase, $ReaderStateTable> {
  $$ReaderStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReaderStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReaderStateTable> {
  $$ReaderStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReaderStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReaderStateTable,
          ReaderStateData,
          $$ReaderStateTableFilterComposer,
          $$ReaderStateTableOrderingComposer,
          $$ReaderStateTableAnnotationComposer,
          $$ReaderStateTableCreateCompanionBuilder,
          $$ReaderStateTableUpdateCompanionBuilder,
          (
            ReaderStateData,
            BaseReferences<_$AppDatabase, $ReaderStateTable, ReaderStateData>,
          ),
          ReaderStateData,
          PrefetchHooks Function()
        > {
  $$ReaderStateTableTableManager(_$AppDatabase db, $ReaderStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReaderStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReaderStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReaderStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ReaderStateCompanion(
                id: id,
                surah: surah,
                ayah: ayah,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surah,
                required int ayah,
                required DateTime updatedAt,
              }) => ReaderStateCompanion.insert(
                id: id,
                surah: surah,
                ayah: ayah,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReaderStateTable, ReaderStateData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReaderStateTable,
                    ReaderStateData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReaderStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReaderStateTable,
      ReaderStateData,
      $$ReaderStateTableFilterComposer,
      $$ReaderStateTableOrderingComposer,
      $$ReaderStateTableAnnotationComposer,
      $$ReaderStateTableCreateCompanionBuilder,
      $$ReaderStateTableUpdateCompanionBuilder,
      (
        ReaderStateData,
        BaseReferences<_$AppDatabase, $ReaderStateTable, ReaderStateData>,
      ),
      ReaderStateData,
      PrefetchHooks Function()
    >;
typedef $$AdhkarProgressTableCreateCompanionBuilder =
    AdhkarProgressCompanion Function({
      required String itemId,
      required int completedCount,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AdhkarProgressTableUpdateCompanionBuilder =
    AdhkarProgressCompanion Function({
      Value<String> itemId,
      Value<int> completedCount,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AdhkarProgressTableFilterComposer
    extends Composer<_$AppDatabase, $AdhkarProgressTable> {
  $$AdhkarProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdhkarProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $AdhkarProgressTable> {
  $$AdhkarProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdhkarProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdhkarProgressTable> {
  $$AdhkarProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AdhkarProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdhkarProgressTable,
          AdhkarProgressData,
          $$AdhkarProgressTableFilterComposer,
          $$AdhkarProgressTableOrderingComposer,
          $$AdhkarProgressTableAnnotationComposer,
          $$AdhkarProgressTableCreateCompanionBuilder,
          $$AdhkarProgressTableUpdateCompanionBuilder,
          (
            AdhkarProgressData,
            BaseReferences<
              _$AppDatabase,
              $AdhkarProgressTable,
              AdhkarProgressData
            >,
          ),
          AdhkarProgressData,
          PrefetchHooks Function()
        > {
  $$AdhkarProgressTableTableManager(
    _$AppDatabase db,
    $AdhkarProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdhkarProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdhkarProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdhkarProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<int> completedCount = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhkarProgressCompanion(
                itemId: itemId,
                completedCount: completedCount,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required int completedCount,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AdhkarProgressCompanion.insert(
                itemId: itemId,
                completedCount: completedCount,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AdhkarProgressTable, AdhkarProgressData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AdhkarProgressTable,
                    AdhkarProgressData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdhkarProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdhkarProgressTable,
      AdhkarProgressData,
      $$AdhkarProgressTableFilterComposer,
      $$AdhkarProgressTableOrderingComposer,
      $$AdhkarProgressTableAnnotationComposer,
      $$AdhkarProgressTableCreateCompanionBuilder,
      $$AdhkarProgressTableUpdateCompanionBuilder,
      (
        AdhkarProgressData,
        BaseReferences<_$AppDatabase, $AdhkarProgressTable, AdhkarProgressData>,
      ),
      AdhkarProgressData,
      PrefetchHooks Function()
    >;
typedef $$AdhkarLogsTableCreateCompanionBuilder = AdhkarLogsCompanion Function({
  Value<int> id,
  required String streakKey,
  Value<String> localDate,
  required DateTime completedAt,
});
typedef $$AdhkarLogsTableUpdateCompanionBuilder = AdhkarLogsCompanion Function({
  Value<int> id,
  Value<String> streakKey,
  Value<String> localDate,
  Value<DateTime> completedAt,
});

class $$AdhkarLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AdhkarLogsTable> {
  $$AdhkarLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streakKey => $composableBuilder(
    column: $table.streakKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdhkarLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AdhkarLogsTable> {
  $$AdhkarLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streakKey => $composableBuilder(
    column: $table.streakKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdhkarLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdhkarLogsTable> {
  $$AdhkarLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get streakKey =>
      $composableBuilder(column: $table.streakKey, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$AdhkarLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdhkarLogsTable,
          AdhkarLog,
          $$AdhkarLogsTableFilterComposer,
          $$AdhkarLogsTableOrderingComposer,
          $$AdhkarLogsTableAnnotationComposer,
          $$AdhkarLogsTableCreateCompanionBuilder,
          $$AdhkarLogsTableUpdateCompanionBuilder,
          (
            AdhkarLog,
            BaseReferences<_$AppDatabase, $AdhkarLogsTable, AdhkarLog>,
          ),
          AdhkarLog,
          PrefetchHooks Function()
        > {
  $$AdhkarLogsTableTableManager(_$AppDatabase db, $AdhkarLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdhkarLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdhkarLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdhkarLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> streakKey = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
              }) => AdhkarLogsCompanion(
                id: id,
                streakKey: streakKey,
                localDate: localDate,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String streakKey,
                Value<String> localDate = const Value.absent(),
                required DateTime completedAt,
              }) => AdhkarLogsCompanion.insert(
                id: id,
                streakKey: streakKey,
                localDate: localDate,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AdhkarLogsTable, AdhkarLog>(table),
                  BaseReferences<_$AppDatabase, $AdhkarLogsTable, AdhkarLog>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdhkarLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdhkarLogsTable,
      AdhkarLog,
      $$AdhkarLogsTableFilterComposer,
      $$AdhkarLogsTableOrderingComposer,
      $$AdhkarLogsTableAnnotationComposer,
      $$AdhkarLogsTableCreateCompanionBuilder,
      $$AdhkarLogsTableUpdateCompanionBuilder,
      (AdhkarLog, BaseReferences<_$AppDatabase, $AdhkarLogsTable, AdhkarLog>),
      AdhkarLog,
      PrefetchHooks Function()
    >;
typedef $$PrayerLogsTableCreateCompanionBuilder = PrayerLogsCompanion Function({
  required String date,
  required String prayer,
  required String status,
  Value<int> rowid,
});
typedef $$PrayerLogsTableUpdateCompanionBuilder = PrayerLogsCompanion Function({
  Value<String> date,
  Value<String> prayer,
  Value<String> status,
  Value<int> rowid,
});

class $$PrayerLogsTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerLogsTable> {
  $$PrayerLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrayerLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerLogsTable> {
  $$PrayerLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrayerLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerLogsTable> {
  $$PrayerLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$PrayerLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrayerLogsTable,
          PrayerLog,
          $$PrayerLogsTableFilterComposer,
          $$PrayerLogsTableOrderingComposer,
          $$PrayerLogsTableAnnotationComposer,
          $$PrayerLogsTableCreateCompanionBuilder,
          $$PrayerLogsTableUpdateCompanionBuilder,
          (
            PrayerLog,
            BaseReferences<_$AppDatabase, $PrayerLogsTable, PrayerLog>,
          ),
          PrayerLog,
          PrefetchHooks Function()
        > {
  $$PrayerLogsTableTableManager(_$AppDatabase db, $PrayerLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> prayer = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrayerLogsCompanion(
                date: date,
                prayer: prayer,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String prayer,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => PrayerLogsCompanion.insert(
                date: date,
                prayer: prayer,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrayerLogsTable, PrayerLog>(table),
                  BaseReferences<_$AppDatabase, $PrayerLogsTable, PrayerLog>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrayerLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrayerLogsTable,
      PrayerLog,
      $$PrayerLogsTableFilterComposer,
      $$PrayerLogsTableOrderingComposer,
      $$PrayerLogsTableAnnotationComposer,
      $$PrayerLogsTableCreateCompanionBuilder,
      $$PrayerLogsTableUpdateCompanionBuilder,
      (PrayerLog, BaseReferences<_$AppDatabase, $PrayerLogsTable, PrayerLog>),
      PrayerLog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db, _db.ayahs);
  $$JuzsTableTableManager get juzs => $$JuzsTableTableManager(_db, _db.juzs);
  $$QuranPagesTableTableManager get quranPages =>
      $$QuranPagesTableTableManager(_db, _db.quranPages);
  $$AdhkarCategoriesTableTableManager get adhkarCategories =>
      $$AdhkarCategoriesTableTableManager(_db, _db.adhkarCategories);
  $$AdhkarItemsTableTableManager get adhkarItems =>
      $$AdhkarItemsTableTableManager(_db, _db.adhkarItems);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$ReaderStateTableTableManager get readerState =>
      $$ReaderStateTableTableManager(_db, _db.readerState);
  $$AdhkarProgressTableTableManager get adhkarProgress =>
      $$AdhkarProgressTableTableManager(_db, _db.adhkarProgress);
  $$AdhkarLogsTableTableManager get adhkarLogs =>
      $$AdhkarLogsTableTableManager(_db, _db.adhkarLogs);
  $$PrayerLogsTableTableManager get prayerLogs =>
      $$PrayerLogsTableTableManager(_db, _db.prayerLogs);
}
