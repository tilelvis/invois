// GENERATED CODE - DO NOT MODIFY BY HAND
//
// ⚠️ HAND-WRITTEN STAND-IN, NOT MACHINE-GENERATED ⚠️
// See the note at the top of stored_product.g.dart — same situation here.
// Before shipping, run:
//   flutter pub run build_runner build --delete-conflicting-outputs
// to replace this with an authoritative generated file.

part of 'stored_stock_movement.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStoredStockMovementCollection on Isar {
  IsarCollection<StoredStockMovement> get storedStockMovements =>
      this.collection();
}

const StoredStockMovementSchema = CollectionSchema(
  name: r'StoredStockMovement',
  id: -2718281828459045235,
  properties: {
    r'movementId': PropertySchema(
      id: 0,
      name: r'movementId',
      type: IsarType.string,
    ),
    r'productId': PropertySchema(
      id: 1,
      name: r'productId',
      type: IsarType.string,
    ),
    r'rawJson': PropertySchema(
      id: 2,
      name: r'rawJson',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 3,
      name: r'timestamp',
      type: IsarType.string,
    ),
  },
  estimateSize: _storedStockMovementEstimateSize,
  serialize: _storedStockMovementSerialize,
  deserialize: _storedStockMovementDeserialize,
  deserializeProp: _storedStockMovementDeserializeProp,
  idName: r'id',
  indexes: {
    r'productId': IndexSchema(
      id: 4127258434506624573,
      name: r'productId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'productId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _storedStockMovementGetId,
  getLinks: _storedStockMovementGetLinks,
  attach: _storedStockMovementAttach,
  version: '3.1.0+1',
);

int _storedStockMovementEstimateSize(
  StoredStockMovement object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.movementId.length * 3;
  bytesCount += 3 + object.productId.length * 3;
  bytesCount += 3 + object.rawJson.length * 3;
  bytesCount += 3 + object.timestamp.length * 3;
  return bytesCount;
}

void _storedStockMovementSerialize(
  StoredStockMovement object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.movementId);
  writer.writeString(offsets[1], object.productId);
  writer.writeString(offsets[2], object.rawJson);
  writer.writeString(offsets[3], object.timestamp);
}

StoredStockMovement _storedStockMovementDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StoredStockMovement();
  object.id = id;
  object.movementId = reader.readString(offsets[0]);
  object.productId = reader.readString(offsets[1]);
  object.rawJson = reader.readString(offsets[2]);
  object.timestamp = reader.readString(offsets[3]);
  return object;
}

P _storedStockMovementDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _storedStockMovementGetId(StoredStockMovement object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _storedStockMovementGetLinks(
    StoredStockMovement object) {
  return [];
}

void _storedStockMovementAttach(
    IsarCollection<dynamic> col, Id id, StoredStockMovement object) {
  object.id = id;
}

extension StoredStockMovementQueryWhereSort
    on QueryBuilder<StoredStockMovement, StoredStockMovement, QWhere> {
  QueryBuilder<StoredStockMovement, StoredStockMovement, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StoredStockMovementQueryWhere on QueryBuilder<StoredStockMovement,
    StoredStockMovement, QWhereClause> {
  QueryBuilder<StoredStockMovement, StoredStockMovement, QAfterWhereClause>
      productIdEqualTo(String productId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'productId',
        value: [productId],
      ));
    });
  }
}

extension StoredStockMovementQuerySortBy
    on QueryBuilder<StoredStockMovement, StoredStockMovement, QSortBy> {
  QueryBuilder<StoredStockMovement, StoredStockMovement, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<StoredStockMovement, StoredStockMovement, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension StoredStockMovementQueryFilter on QueryBuilder<StoredStockMovement,
    StoredStockMovement, QFilterCondition> {
  QueryBuilder<StoredStockMovement, StoredStockMovement, QAfterFilterCondition>
      productIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }
}
