// GENERATED CODE - DO NOT MODIFY BY HAND
//
// ⚠️ HAND-WRITTEN STAND-IN, NOT MACHINE-GENERATED ⚠️
// This project's sandbox build had no Flutter/Dart SDK available to run
// `isar_generator`/`build_runner`, so this file was written by hand to match
// the shape `build_runner` produces (see stored_invoice.g.dart as reference).
// It covers exactly the operations StorageService/products_list_provider use
// (put/get/delete by productId, sort by name) — it intentionally omits the
// full filter/distinct/property query-extension surface a real codegen run
// would include for every field, since nothing in this feature calls those.
// Before shipping, run:
//   flutter pub run build_runner build --delete-conflicting-outputs
// to replace this with an authoritative generated file.

part of 'stored_product.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStoredProductCollection on Isar {
  IsarCollection<StoredProduct> get storedProducts => this.collection();
}

const StoredProductSchema = CollectionSchema(
  name: r'StoredProduct',
  id: 6773461337323947101,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    ),
    r'onHandQuantity': PropertySchema(
      id: 2,
      name: r'onHandQuantity',
      type: IsarType.long,
    ),
    r'productId': PropertySchema(
      id: 3,
      name: r'productId',
      type: IsarType.string,
    ),
    r'rawJson': PropertySchema(
      id: 4,
      name: r'rawJson',
      type: IsarType.string,
    ),
    r'sku': PropertySchema(
      id: 5,
      name: r'sku',
      type: IsarType.string,
    ),
  },
  estimateSize: _storedProductEstimateSize,
  serialize: _storedProductSerialize,
  deserialize: _storedProductDeserialize,
  deserializeProp: _storedProductDeserializeProp,
  idName: r'id',
  indexes: {
    r'productId': IndexSchema(
      id: -8393618853396978167,
      name: r'productId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'productId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'sku': IndexSchema(
      id: 1394442718532790585,
      name: r'sku',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sku',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _storedProductGetId,
  getLinks: _storedProductGetLinks,
  attach: _storedProductAttach,
  version: '3.1.0+1',
);

int _storedProductEstimateSize(
  StoredProduct object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.productId.length * 3;
  bytesCount += 3 + object.rawJson.length * 3;
  {
    final value = object.sku;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _storedProductSerialize(
  StoredProduct object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeString(offsets[1], object.name);
  writer.writeLong(offsets[2], object.onHandQuantity);
  writer.writeString(offsets[3], object.productId);
  writer.writeString(offsets[4], object.rawJson);
  writer.writeString(offsets[5], object.sku);
}

StoredProduct _storedProductDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StoredProduct();
  object.category = reader.readString(offsets[0]);
  object.id = id;
  object.name = reader.readString(offsets[1]);
  object.onHandQuantity = reader.readLong(offsets[2]);
  object.productId = reader.readString(offsets[3]);
  object.rawJson = reader.readString(offsets[4]);
  object.sku = reader.readStringOrNull(offsets[5]);
  return object;
}

P _storedProductDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _storedProductGetId(StoredProduct object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _storedProductGetLinks(StoredProduct object) {
  return [];
}

void _storedProductAttach(
    IsarCollection<dynamic> col, Id id, StoredProduct object) {
  object.id = id;
}

extension StoredProductByIndex on IsarCollection<StoredProduct> {
  Future<StoredProduct?> getByProductId(String productId) {
    return getByIndex(r'productId', [productId]);
  }

  StoredProduct? getByProductIdSync(String productId) {
    return getByIndexSync(r'productId', [productId]);
  }

  Future<bool> deleteByProductId(String productId) {
    return deleteByIndex(r'productId', [productId]);
  }

  bool deleteByProductIdSync(String productId) {
    return deleteByIndexSync(r'productId', [productId]);
  }

  Future<Id> putByProductId(StoredProduct object) {
    return putByIndex(r'productId', object);
  }

  Id putByProductIdSync(StoredProduct object, {bool saveLinks = true}) {
    return putByIndexSync(r'productId', object, saveLinks: saveLinks);
  }
}

extension StoredProductQueryWhereSort
    on QueryBuilder<StoredProduct, StoredProduct, QWhere> {
  QueryBuilder<StoredProduct, StoredProduct, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StoredProductQueryWhere
    on QueryBuilder<StoredProduct, StoredProduct, QWhereClause> {
  QueryBuilder<StoredProduct, StoredProduct, QAfterWhereClause> productIdEqualTo(
      String productId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'productId',
        value: [productId],
      ));
    });
  }

  QueryBuilder<StoredProduct, StoredProduct, QAfterWhereClause> skuEqualTo(
      String? sku) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sku',
        value: [sku],
      ));
    });
  }
}

extension StoredProductQuerySortBy
    on QueryBuilder<StoredProduct, StoredProduct, QSortBy> {
  QueryBuilder<StoredProduct, StoredProduct, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<StoredProduct, StoredProduct, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<StoredProduct, StoredProduct, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<StoredProduct, StoredProduct, QAfterSortBy>
      sortByOnHandQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onHandQuantity', Sort.asc);
    });
  }
}

extension StoredProductQueryWhereDistinct
    on QueryBuilder<StoredProduct, StoredProduct, QDistinct> {
  QueryBuilder<StoredProduct, StoredProduct, QDistinct> distinctByProductId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId', caseSensitive: caseSensitive);
    });
  }
}
