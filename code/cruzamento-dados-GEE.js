/**
 * Estatísticas de Área por Classe Textural e Cobertura do Solo
 * 
 * Este script calcula estatísticas de área para classes texturais do solo combinadas com classes de cobertura do solo,
 * agrupadas por bioma e unidade federativa no Brasil. Os resultados são exportados como um arquivo CSV.
 * 
 * Descrição:
 * - Carrega dados de textura do solo (frações de areia, silte e argila) para a camada de 0-30 cm.
 * - Classifica a textura do solo com base nas frações em classes predefinidas.
 * - Carrega dados de uso e cobertura do solo da Coleção 9 do MapBiomas.
 * - Remapeia as classes de cobertura do solo em níveis principais, excluindo corpos d'água.
 * - Combina textura do solo e cobertura do solo em uma única imagem.
 * - Calcula estatísticas de área agrupadas por classe textural, classe de cobertura, bioma e unidade federativa.
 * - Exporta os resultados para o Google Drive como um arquivo CSV.
 * 
 * Nota: Este script utiliza a API JavaScript do Google Earth Engine.
 */

// --- opções
var scale = 30;
var version = '2025_04_08';
// var version = 'old_collection2_2024_11_29-1';
var description = version + '_texture_niveis_YEAR';
var folder = 'GTSOLO-Workshop';

// --- Datasets
// Limites dos biomas
// var biomas = ee.FeatureCollection("projects/mapbiomas-workspace/AUXILIAR/biomas_IBGE_250mil");

var biomas = ee.FeatureCollection('projects/ee-marcoscardoso/assets/oeste-pr')

var bounds = biomas.geometry().bounds();
// var bounds = geometry;

// Limites geométricos dos biomas para o calculo de área, comentar para testes em uma area reduzida
// var bounds = biomas.geometry().bounds();
// var bounds = geometry;

// Limites das unidades federativas (estados)
var estados = ee.FeatureCollection('projects/ee-marcoscardoso/assets/oeste-pr')
  .map(function(feature){
    return feature.set({
      CD_RGI: ee.Number.parse(feature.get('CD_RGI')),
    });
  });

// Máscara de água
var water_mask = ee.Image('projects/mapbiomas-workspace/SOLOS/COVARIAVEIS/GT_MASK_SUBMERGED_AND_ANTHROPIZED_BODIES')
  .select('classification_2023');

// Máscara para áreas que não são água
var soilOnlyMask = water_mask.mask().neq(1); 
var br_soil = soilOnlyMask.clip(biomas);

// Importando as camadas de granulometria (areia, argila e silte) para 0-30 cm
var sand = ee.Image('projects/mapbiomas-public/assets/brazil/soil/collection2/mapbiomas_soil_collection2_granulometry_sand_percentage')
  .select('sand_000_030cm');
var clay = ee.Image('projects/mapbiomas-public/assets/brazil/soil/collection2/mapbiomas_soil_collection2_granulometry_clay_percentage')
  .select('clay_000_030cm');
var silt = ee.Image('projects/mapbiomas-public/assets/brazil/soil/collection2/mapbiomas_soil_collection2_granulometry_silt_percentage')
  .select('silt_000_030cm');

// Combinação das frações em uma única imagem para a camada 0-30 cm
var soilFractions_0_30cm = sand
  .addBands(silt)
  .addBands(clay)
  .rename(['sand', 'silt', 'clay']);

// Classificação da textura do solo
var soilTexture = ee.Image().expression(
    '(clay >= 60) ? 1 : ' + // Muito argilosa
    '((clay >= 35) && (clay < 60)) ? 2 : ' + // Argilosa
    '((silt >= 50) && (sand < 15) && (clay < 35)) ? 3 : ' + // Siltosa
    '((sand >= 70) && (sand < (70 + (35 - clay))) && (clay < 35)) ? 4 : ' + // Arenosa
    '5', // Média
    {
      clay: soilFractions_0_30cm.select('clay'),
      sand: soilFractions_0_30cm.select('sand'),
      silt: soilFractions_0_30cm.select('silt')
    }
  ).rename('soil_texture')
  .updateMask(br_soil);

// var soilTexture = ee.Image('projects/mapbiomas-public/assets/brazil/soil/collection2/mapbiomas_soil_collection2_textural_groups');

// Visualização da textura do solo
Map.addLayer(soilTexture, {min:1, max:5}, 'Soil Texture');

// Carregando a camada de uso e cobertura do solo (Coleção 9)
var landCover_original = ee.Image('projects/mapbiomas-public/assets/brazil/lulc/collection9/mapbiomas_collection90_integration_v1');

// Visualização da cobertura do solo remapeada
Map.addLayer(landCover_original, {
    'bands': 'classification_2023',
    'palette': require('users/mapbiomas/modules:Palettes.js').get('classification8'),
    'min': 0,
    'max': 69
}, 'Uso e Cobertura do Solo 2023', false);

// Combinação da textura do solo com a cobertura do solo
var soil_texture_landcover = landCover_original.add(soilTexture.multiply(100)).selfMask();

// Visualização da combinação
Map.addLayer(soil_texture_landcover, {
    'bands': 'classification_2023',
    'palette': require('users/mapbiomas/modules:Palettes.js').get('classification8'),
    'min': 0,
    'max': 69
}, 'Cobertura do Solo e Textura do Solo 2023', false);


// NEW Nova coleção de carbono orgânico do solo
var carbonStack = ee.Image('projects/mapbiomas-public/assets/brazil/soil/collection2/mapbiomas_soil_collection2_soc_t_ha_000_030cm')

var carbonStack_classes = carbonStack.divide(10).int16();
carbonStack_classes = carbonStack_classes.where(carbonStack_classes.gte(8),8);

soil_texture_landcover = soil_texture_landcover.multiply(10).add(carbonStack_classes);

// Cálculo da área em hectares
var pixelAreaHa = ee.Image.pixelArea().divide(1e4); // Converter m² para hectares
var pixelTonelada = carbonStack.multiply(pixelAreaHa); // Converter m² para hectares

// Imagens dos biomas e estados para mapeamento territorial
var biomas_img = ee.Image().paint(biomas, 'CD_Bioma');
var estados_img = ee.Image().paint(estados, 'CD_RGI');
var territory_img = biomas_img.add(estados_img.multiply(10));

// Definição dos dicionários de legenda
var textureClasses = ee.Dictionary({
  0:'Não observado',
  1:'Muito argilosa',
  2:'Argilosa',
  3:'Siltosa',
  4:'Arenosa',
  5:'Média',
});

// Definição dos dicionários de legenda
var legend_cos = ee.Dictionary({
  0:'1. 0 até 10 ton/ha',
  1:'2. 10 até 20 ton/ha',
  2:'3. 20 até 30 ton/ha',
  3:'4. 30 até 40 ton/ha',
  4:'5. 40 até 50 ton/ha',
  5:'6. 50 até 60 ton/ha',
  6:'7. 60 até 70 ton/ha',
  7:'8. 70 até 80 ton/ha',
  8:'9. mais de 80 ton/h',
});

// var biomasClasses = ee.Dictionary({
//   0:'Não observado',
//   1:'Amazônia',
//   2:'Caatinga',
//   3:'Cerrado',
//   4:'Mata Atlântica',
//   5:'Pampa',
//   6:'Pantanal',
// });

// var unidadeFederativaClasses = ee.Dictionary({
//   0: 'Não observado',
//   11: 'Rondônia',
//   12: 'Acre',
//   13: 'Amazonas',
//   14: 'Roraima',
//   15: 'Pará',
//   16: 'Amapá',
//   17: 'Tocantins',
//   21: 'Maranhão',
//   22: 'Piauí',
//   23: 'Ceará',
//   24: 'Rio Grande do Norte',
//   25: 'Paraíba',
//   26: 'Pernambuco',
//   27: 'Alagoas',
//   28: 'Sergipe',
//   29: 'Bahia',
//   31: 'Minas Gerais',
//   32: 'Espírito Santo',
//   33: 'Rio de Janeiro',
//   35: 'São Paulo',
//   41: 'Paraná',
//   42: 'Santa Catarina',
//   43: 'Rio Grande do Sul',
//   50: 'Mato Grosso do Sul',
//   51: 'Mato Grosso',
//   52: 'Goiás',
//   53: 'Distrito Federal'
// });

var unidadeFederativaClasses = ee.Dictionary({
  0: 'Não observado',
  410006: 'Cascavel',
  410007: 'Foz do Iguaçu',
  410008: 'Toledo',
  410013: 'Marechal Cândido Rondon'
});


// var ufClasses = ee.Dictionary({
//   0: 'Não observado',
//   11: 'RO',
//   12: 'AC',
//   13: 'AM',
//   14: 'RR',
//   15: 'PA',
//   16: 'AP',
//   17: 'TO',
//   21: 'MA',
//   22: 'PI',
//   23: 'CE',
//   24: 'RN',
//   25: 'PB',
//   26: 'PE',
//   27: 'AL',
//   28: 'SE',
//   29: 'BA',
//   31: 'MG',
//   32: 'ES',
//   33: 'RJ',
//   35: 'SP',
//   41: 'PR',
//   42: 'SC',
//   43: 'RS',
//   50: 'MS',
//   51: 'MT',
//   52: 'GO',
//   53: 'DF'
// });


var legends = require('users/wallacesilva/mapbiomas-solos:COLECAO_01/tools/module_legends.js');

var  niveis = ee.Dictionary(legends.get('lulc_mbc08_niveis')),
     nivel_0 = ee.Dictionary(legends.get('lulc_mbc08_nivel_0')),
     nivel_1 = ee.Dictionary(legends.get('lulc_mbc08_nivel_1')),
     nivel_1_1 = ee.Dictionary(legends.get('lulc_mbc08_nivel_1_1')),
     nivel_2 = ee.Dictionary(legends.get('lulc_mbc08_nivel_2')),
     nivel_3 = ee.Dictionary(legends.get('lulc_mbc08_nivel_3')),
     nivel_4 = ee.Dictionary(legends.get('lulc_mbc08_nivel_4'));

// Cálculo das estatísticas de área
pixelTonelada.bandNames().evaluate(function(bandnames){
  
  var tables = bandnames
    // .slice(-1) // Utilizando apenas o último ano (2023)
    .map(function(bandname){

      var year = bandname.slice(-4);

      // --- --- ---
      var observed_area = pixelAreaHa
        .addBands(soil_texture_landcover.select('classification_' + year))
        .addBands(territory_img);
        
      var reduce_area = observed_area.reduceRegion({
        reducer: ee.Reducer.sum().group(1, 'territory').group(1, 'classe'),
        geometry: bounds,
        scale: scale,
        maxPixels: 1e13,
      }).get("groups");
      
      var table_area = ee.List(reduce_area)
        .map(function(obj_n1){
          obj_n1 = ee.Dictionary(obj_n1);
          var classe_int = obj_n1.getNumber('classe').int();
          var cos_classe_int = classe_int.mod(10).int();
          classe_int = classe_int.divide(10).int();
          
          return ee.FeatureCollection(ee.List(obj_n1.get('groups'))
            .map(function(obj_n2){
              obj_n2 = ee.Dictionary(obj_n2);
              
              var territory_int = obj_n2.getNumber('territory').int();
              
              var area_ha = obj_n2.getNumber('sum');
              
              return ee.Feature(null)
                .set({
                  'index': ee.String(classe_int).cat(cos_classe_int).cat('-').cat(territory_int).cat('-').cat(year),
                  'Área ha': area_ha,
                  'Ano': year,
                  'classe textural int': classe_int.divide(100).int(),
                  'cobertura int': classe_int.mod(100).int(),
                  'Classe textural': textureClasses.get(classe_int.divide(100).int()),
                  'Cobertura n0': nivel_0.get(classe_int.mod(100).int()),
                  'Cobertura n1': nivel_1.get(classe_int.mod(100).int()),
                  'Cobertura n1_1': nivel_1_1.get(classe_int.mod(100).int()),
                  'Cobertura n2': nivel_2.get(classe_int.mod(100).int()),
                  'Cobertura n3': nivel_3.get(classe_int.mod(100).int()),
                  'Cobertura n4': nivel_4.get(classe_int.mod(100).int()),
                  'Intervalo de COS': legend_cos.get(cos_classe_int),
                  'intervalo de cos': cos_classe_int,
                  // 'Bioma': biomasClasses.get(territory_int.mod(10).int()),
                  'Unidade Federativa': unidadeFederativaClasses.get(territory_int.divide(10).int()),
                  // 'UF': ufClasses.get(territory_int.divide(10).int()),
                  // 'classe_int': classe_int,
                  // 'territory_int': territory_int,
                });
            }));
          
        });
      
      table_area = ee.FeatureCollection(table_area).flatten();
      
      // --- --- ---
      var observed_toneladas = pixelTonelada.select('prediction_' + year)
        .addBands(soil_texture_landcover.select('classification_' + year))
        .addBands(territory_img);
        

      var reduce_toneladas = observed_toneladas
        .reduceRegion({
          reducer: ee.Reducer.sum().group(1, 'territory').group(1, 'classe'),
          geometry: bounds,
          scale: scale,
          maxPixels: 1e13,
        }).get("groups");
      
      var table_toneladas = ee.List(reduce_toneladas)
        .map(function(obj_n1){
          obj_n1 = ee.Dictionary(obj_n1);
          var classe_int = obj_n1.getNumber('classe').int();
          var cos_classe_int = classe_int.mod(10).int();
          classe_int = classe_int.divide(10).int();

          return ee.FeatureCollection(ee.List(obj_n1.get('groups'))
            .map(function(obj_n2){
              obj_n2 = ee.Dictionary(obj_n2);
              
              var territory_int = obj_n2.getNumber('territory').int();
              
              var toneladas_cos = obj_n2.getNumber('sum');
              
              return ee.Feature(null)
                .set({
                  'index': ee.String(classe_int).cat(cos_classe_int).cat('-').cat(territory_int).cat('-').cat(year),
                  'Toneladas de COS': toneladas_cos,
                });
            }));
          
        });
      
      table_toneladas = ee.FeatureCollection(table_toneladas).flatten();
      
      // --- --- ---
      // Junção das tabelas de quantificação do total de área em hectares e carbono organico do solo em toneladas
      var  joinKey = 'index';
      var join = ee.Join.inner();
      var filter_join = ee.Filter.equals({
        'leftField':joinKey,
        'rightField':joinKey,
      });
      
      var table = join.apply(table_area, table_toneladas, filter_join)
      // Função para copiar as propriedades de dois Features juntos
      .map(function getJoin (feature) {
        return  ee.Feature(null)
          .copyProperties(feature.get('primary'))
          .copyProperties(feature.get('secondary'));
      });
      
      // Verificar o resultado
      // print('Joined Features:', joinedFeatures);
      // print('toneladas:', toneladas);
      // print('areas:', areas);
      
    print(year,ee.FeatureCollection(table).limit(100))
      
      // return ee.FeatureCollection(table);
    Export.table.toDrive({
        collection: ee.FeatureCollection(table),
        description: description.replace('YEAR',year),
        fileFormat: 'CSV',
        folder: folder,
         selectors:[
          // 'index',
          'classe textural int',
          'Classe textural',
          'cobertura int',
          'Cobertura n0',
          'Cobertura n1_1',
          'Cobertura n2',
          'Cobertura n3',
          'Cobertura n4',
          'intervalo de cos',
          'Intervalo de COS',
          'Ano',
          // 'Bioma',
          // 'UF',
          'Unidade Federativa',
          'Área ha',
          'Toneladas de COS',
          // classe_int	territory_int	
          ]
      });
          });
  
  // tables = ee.FeatureCollection(tables).flatten();

  // print('tables', tables.limit(10));
  
  // // Exportar para o Drive
  // Export.table.toDrive({
  //   collection: tables,
  //   description: description,
  //   fileFormat: 'CSV',
  //   folder: folder,
  //   selectors:[
  //     // 'index',
  //     'classe textural int',
  //     'Classe textural',
  //     'cobertura int',
  //     'Cobertura n0',
  //     'Cobertura n1_1',
  //     'Cobertura n2',
  //     'Cobertura n3',
  //     'Cobertura n4',
  //     'Ano',
  //     'Bioma',
  //     'UF',
  //     'Unidade Federativa',
  //     'Área ha',
  //     'Toneladas de COS',
  //     // classe_int	territory_int	
  //     ]
  // });
  
});
