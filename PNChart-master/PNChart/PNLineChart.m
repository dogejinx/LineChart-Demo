//
//  PNLineChart.m
//  PNChartDemo
//
//  Created by kevin on 11/7/13.
//  Copyright (c) 2013年 kevinzhow. All rights reserved.
//

#import "PNLineChart.h"
#import "PNColor.h"
#import "PNChartLabel.h"
#import "PNLineChartData.h"
#import "PNLineChartDataItem.h"
#import <CoreText/CoreText.h>

@interface PNLineChart ()

@property(nonatomic) NSMutableArray *chartLineArray;  // Array[CAShapeLayer]
@property(nonatomic) NSMutableArray *chartFillArray;  // Array[CAShapeLayer] save the fill layer
@property(nonatomic) NSMutableArray *chartPointArray; // Array[CAShapeLayer] save the point layer

@property(nonatomic) NSMutableArray *chartPath;       // Array of line path, one for each line.
@property(nonatomic) NSMutableArray *fillPath;        // Array of fill path, one for each fill.
@property(nonatomic) NSMutableArray *pointPath;       // Array of point path, one for each line
@property(nonatomic) NSMutableArray *endPointsOfPath; // Array of start and end points of each line path, one for each line

@property(nonatomic) CABasicAnimation *pathAnimation; // will be set to nil if _displayAnimation is NO

// display grade
@property(nonatomic) NSMutableArray *gradeStringPaths;

// 辅助线
@property(nonatomic) CAShapeLayer *auxiliaryLineShapeLayer;
// 辅助Label
@property(nonatomic) UILabel *auxiliaryLabel;
// 简便数据model
@property(nonatomic) NSMutableArray *chartModelArray;

@end

@implementation PNLineChart

@synthesize pathAnimation = _pathAnimation;

#pragma mark initialization

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];

    if (self) {
        [self setupDefaultValues];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self setupDefaultValues];
    }

    return self;
}


#pragma mark instance methods

- (void)setYLabels {
    CGFloat yStep = (_yValueMax - _yValueMin) / _yLabelNum;
    CGFloat yStepHeight = _chartCavanHeight / _yLabelNum;

    if (_yChartLabels) {
        for (PNChartLabel *label in _yChartLabels) {
            [label removeFromSuperview];
        }
    } else {
        _yChartLabels = [NSMutableArray new];
    }

    if (yStep == 0.0) {
        PNChartLabel *minLabel = [[PNChartLabel alloc] initWithFrame:CGRectMake(0.0, (NSInteger) _chartCavanHeight, (NSInteger) _chartMarginBottom, (NSInteger) _yLabelHeight)];
        minLabel.text = [self formatYLabel:0.0];
        [self setCustomStyleForYLabel:minLabel];
        [self addSubview:minLabel];
        [_yChartLabels addObject:minLabel];

        PNChartLabel *midLabel = [[PNChartLabel alloc] initWithFrame:CGRectMake(0.0, (NSInteger) (_chartCavanHeight / 2), (NSInteger) _chartMarginBottom, (NSInteger) _yLabelHeight)];
        midLabel.text = [self formatYLabel:_yValueMax];
        [self setCustomStyleForYLabel:midLabel];
        [self addSubview:midLabel];
        [_yChartLabels addObject:midLabel];

        PNChartLabel *maxLabel = [[PNChartLabel alloc] initWithFrame:CGRectMake(0.0, 0.0, (NSInteger) _chartMarginBottom, (NSInteger) _yLabelHeight)];
        maxLabel.text = [self formatYLabel:_yValueMax * 2];
        [self setCustomStyleForYLabel:maxLabel];
        [self addSubview:maxLabel];
        [_yChartLabels addObject:maxLabel];

    } else {
        NSInteger index = 0;
        NSInteger num = _yLabelNum + 1;

        while (num > 0) {
            PNChartLabel *label = [[PNChartLabel alloc] initWithFrame:CGRectMake(0.0, (NSInteger) (_chartMarginTop + _chartCavanHeight - index * yStepHeight), (NSInteger) _chartMarginLeft, (NSInteger) _yLabelHeight)];
            [label setTextAlignment:NSTextAlignmentRight];
            label.text = [self formatYLabel:_yValueMin + (yStep * index)];
            [self setCustomStyleForYLabel:label];
            [self addSubview:label];
            [_yChartLabels addObject:label];
            index += 1;
            num -= 1;
        }
    }
}

#pragma mark - 绘制 y轴 的label
- (void)setYLabels:(NSArray *)yLabels {
    _showGenYLabels = NO;
    _yLabelNum = yLabels.count - 1;

    CGFloat yLabelHeight;
    if (_showLabel) {
        yLabelHeight = _chartCavanHeight / [yLabels count];
    } else {
        yLabelHeight = (self.frame.size.height) / [yLabels count];
    }

    return [self setYLabels:yLabels withHeight:yLabelHeight];
}

- (void)setYLabels:(NSArray *)yLabels withHeight:(CGFloat)height {
    _yLabels = yLabels;
    _yLabelHeight = height;
    if (_yChartLabels) {
        for (PNChartLabel *label in _yChartLabels) {
            [label removeFromSuperview];
        }
    } else {
        _yChartLabels = [NSMutableArray new];
    }

    NSString *labelText;

    if (_showLabel) {
        CGFloat yStepHeight = _chartCavanHeight / _yLabelNum;

        for (int index = 0; index < yLabels.count; index++) {
            labelText = yLabels[index];

            NSInteger y = (NSInteger) (_chartMarginTop + _chartCavanHeight - index * yStepHeight - 0.5 * height);

            PNChartLabel *label = [[PNChartLabel alloc] initWithFrame:CGRectMake(0.0, y, (NSInteger) _chartMarginLeft * 0.9, (NSInteger) _yLabelHeight)];
            [label setTextAlignment:NSTextAlignmentRight];
            label.text = labelText;
            [self setCustomStyleForYLabel:label];
            [self addSubview:label];
            [_yChartLabels addObject:label];
        }
    }
}

- (CGFloat)computeEqualWidthForXLabels:(NSArray *)xLabels {
    CGFloat xLabelWidth;

    if (_showLabel) {
        xLabelWidth = _chartCavanWidth / [xLabels count];
    } else {
        xLabelWidth = (self.frame.size.width) / [xLabels count];
    }

    return xLabelWidth;
}

#pragma mark - 绘制 x轴 的label
- (void)setXLabels:(NSArray *)xLabels {
    CGFloat xLabelWidth;

    if (_showLabel) {
        xLabelWidth = _chartCavanWidth / [xLabels count];
    } else {
        xLabelWidth = (self.frame.size.width - _chartMarginLeft - _chartMarginRight) / [xLabels count];
    }

    return [self setXLabels:xLabels withWidth:xLabelWidth];
}

- (void)setXLabels:(NSArray *)xLabels withWidth:(CGFloat)width {
    _xLabels = xLabels;
    _xLabelWidth = width;
    if (_xChartLabels) {
        for (PNChartLabel *label in _xChartLabels) {
            [label removeFromSuperview];
        }
    } else {
        _xChartLabels = [NSMutableArray new];
    }

    NSString *labelText;

    if (_showLabel) {
        for (int index = 0; index < xLabels.count; index++) {
            labelText = xLabels[index];

            NSInteger x = (index * _xLabelWidth + _chartMarginLeft - _xLabelWidth / 2.0);
            NSInteger y = _chartMarginTop + _chartCavanHeight + 10;

            PNChartLabel *label = [[PNChartLabel alloc] initWithFrame:CGRectMake(x, y, (NSInteger) _xLabelWidth, _chartMarginBottom - 20)];
            [label setTextAlignment:NSTextAlignmentCenter];
            label.text = labelText;
            [self setCustomStyleForXLabel:label];
            [self addSubview:label];
            [_xChartLabels addObject:label];
        }
    }
}

- (void)setCustomStyleForXLabel:(UILabel *)label {
    if (_xLabelFont) {
        label.font = _xLabelFont;
    }

    if (_xLabelColor) {
        label.textColor = _xLabelColor;
    }

}

- (void)setCustomStyleForYLabel:(UILabel *)label {
    if (_yLabelFont) {
        label.font = _yLabelFont;
    }

    if (_yLabelColor) {
        label.textColor = _yLabelColor;
    }
}

#pragma mark - Touch at point

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchPoint:touches withEvent:event];
    [self touchKeyPoint:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchPoint:touches withEvent:event];
    [self touchKeyPoint:touches withEvent:event];
}

- (void)touchPoint:(NSSet *)touches withEvent:(UIEvent *)event {
    // Get the point user touched
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];

    for (NSInteger p = _pathPoints.count - 1; p >= 0; p--) {
        NSArray *linePointsArray = _endPointsOfPath[p];

        for (int i = 0; i < (int) linePointsArray.count - 1; i += 2) {
            CGPoint p1 = [linePointsArray[i] CGPointValue];
            CGPoint p2 = [linePointsArray[i + 1] CGPointValue];

            // Closest distance from point to line
            float distance = fabs(((p2.x - p1.x) * (touchPoint.y - p1.y)) - ((p1.x - touchPoint.x) * (p1.y - p2.y)));
            distance /= hypot(p2.x - p1.x, p1.y - p2.y);

            if (distance <= 5.0) {
                // Conform to delegate parameters, figure out what bezier path this CGPoint belongs to.
                for (UIBezierPath *path in _chartPath) {
                    BOOL pointContainsPath = CGPathContainsPoint(path.CGPath, NULL, p1, NO);

                    if (pointContainsPath) {
                        [_delegate userClickedOnLinePoint:touchPoint lineIndex:[_chartPath indexOfObject:path]];

                        return;
                    }
                }
            }
        }
    }
}

- (void)touchKeyPoint:(NSSet *)touches withEvent:(UIEvent *)event {
    // Get the point user touched
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];

    for (NSInteger p = _pathPoints.count - 1; p >= 0; p--) {
        NSArray *linePointsArray = _pathPoints[p];

        for (int i = 0; i < (int) linePointsArray.count - 1; i += 1) {
            CGPoint p1 = [linePointsArray[i] CGPointValue];
            CGPoint p2 = [linePointsArray[i + 1] CGPointValue];

            float distanceToP1 = fabs(hypot(touchPoint.x - p1.x, touchPoint.y - p1.y));
            float distanceToP2 = hypot(touchPoint.x - p2.x, touchPoint.y - p2.y);

            float distance = MIN(distanceToP1, distanceToP2);

            if (distance <= 20.0) {// 调整手指touch响应范围(越大，响应范围越大)
                CGPoint keyPoint = (distance == distanceToP2) ? p2 : p1;
                NSInteger keyIndex = distance == distanceToP2 ? i + 1 : i;
                [self drawAuxiliaryLine:keyPoint line:p index:keyIndex];
                [_delegate userClickedOnLineKeyPoint:touchPoint
                                           lineIndex:p
                                          pointIndex:keyIndex];

                return;
            }
        }
    }
}

#pragma mark - 绘制 辅助线
- (void)drawAuxiliaryLine:(CGPoint)point line:(NSInteger)line index:(NSInteger)index {
    
    if (nil != _auxiliaryLineShapeLayer) {
        [_auxiliaryLineShapeLayer removeFromSuperlayer];
    }
    
    if (nil != _auxiliaryLabel) {
        [_auxiliaryLabel removeFromSuperview];
    }
    
    {
        CAShapeLayer *auxiliary = [CAShapeLayer layer];
        auxiliary.strokeColor = [UIColorFromRGB(0x3d99ed) CGColor];
        auxiliary.lineCap = kCALineCapRound;
        auxiliary.lineJoin = kCALineJoinRound;
        auxiliary.fillColor = [[UIColor whiteColor] CGColor];
        auxiliary.lineWidth = 2.f;
        _auxiliaryLineShapeLayer = auxiliary;
        [self.layer addSublayer:auxiliary];
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        
        CGFloat inflexionWidth = 14.0f;
        CGRect squareRect = CGRectMake(point.x - inflexionWidth / 2, point.y - inflexionWidth / 2, inflexionWidth, inflexionWidth);
        CGPoint squareCenter = CGPointMake(squareRect.origin.x + (squareRect.size.width / 2), squareRect.origin.y + (squareRect.size.height / 2));
        
        [path moveToPoint:CGPointMake(squareCenter.x - (inflexionWidth / 2), squareCenter.y - (inflexionWidth / 2))];
        [path addLineToPoint:CGPointMake(squareCenter.x + (inflexionWidth / 2), squareCenter.y - (inflexionWidth / 2))];
        [path addLineToPoint:CGPointMake(squareCenter.x + (inflexionWidth / 2), squareCenter.y + (inflexionWidth / 2))];
        [path addLineToPoint:CGPointMake(squareCenter.x - (inflexionWidth / 2), squareCenter.y + (inflexionWidth / 2))];
        [path closePath];
        
        [path moveToPoint:CGPointMake(squareCenter.x, _chartMarginTop)];
        [path addLineToPoint:CGPointMake(squareCenter.x, _chartMarginTop + _chartCavanHeight)];
        
        
        auxiliary.path = path.CGPath;
        
        auxiliary.strokeEnd = 1.0;
    }
    
    {
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(0, 0, 200, 30);
        label.layer.masksToBounds = YES;
        label.layer.cornerRadius = 4.f;
        label.font = [UIFont systemFontOfSize:15.f];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = UIColorFromRGB(0x3d99ed);
        label.textColor = [UIColor whiteColor];
        _auxiliaryLabel = label;
        [self addSubview:label];
        
        PNLineChartData *data = self.chartData[line];
        NSString *str = [NSString stringWithFormat:@"%@ %1.f 万票房",_xLabels[index],data.getData(index).rawY];
        
        CGSize size = [PNLineChart sizeOfString:str withWidth:MAXFLOAT font:label.font];
        CGFloat size_width = size.width + 10;
        
        CGFloat x = point.x - (size_width / 2.f);
        if (x<_chartMarginLeft) {
            x = _chartMarginLeft;
        }
        else if ((x + size_width)>(self.bounds.size.width - _chartMarginRight)) {
            x = (self.bounds.size.width - _chartMarginRight) - size_width;
        }
    
        CGFloat y = (_chartMarginTop - 10)/2.f + 10 - label.frame.size.height/2.f;
        
        
        label.frame = CGRectMake(x, y, size_width, 30);
        label.text = str;
    }
}


#pragma mark - 绘制 图表

- (void)strokeChart {
    _chartPath = [[NSMutableArray alloc] init];
    _fillPath = [[NSMutableArray alloc] init];
    _pointPath = [[NSMutableArray alloc] init];
    _gradeStringPaths = [NSMutableArray array];

    [self calculateChartPath:_chartPath andFillPath:_fillPath andPointsPath:_pointPath andPathKeyPoints:_pathPoints andPathStartEndPoints:_endPointsOfPath];
    // Draw each line
    for (NSUInteger lineIndex = 0; lineIndex < self.chartData.count; lineIndex++) {
        PNLineChartData *chartData = self.chartData[lineIndex];
        CAShapeLayer *chartLine = (CAShapeLayer *) self.chartLineArray[lineIndex];
        CAShapeLayer *fillLayer = (CAShapeLayer *) self.chartFillArray[lineIndex];
        CAShapeLayer *pointLayer = (CAShapeLayer *) self.chartPointArray[lineIndex];
        UIGraphicsBeginImageContext(self.frame.size);
        // setup the color of the chart line
        if (chartData.color) {
            chartLine.strokeColor = [[chartData.color colorWithAlphaComponent:chartData.alpha] CGColor];
            if (chartData.inflexionPointColor) {
                pointLayer.strokeColor = [[chartData.inflexionPointColor
                        colorWithAlphaComponent:chartData.alpha] CGColor];
            }
            if (chartData.fillColor) {
                fillLayer.fillColor = [[chartData.fillColor colorWithAlphaComponent:1.f] CGColor];
                fillLayer.opacity = 0.5;
            }
        } else {
            chartLine.strokeColor = [PNGreen CGColor];
            fillLayer.strokeColor = [PNGreen CGColor];
            pointLayer.strokeColor = [PNGreen CGColor];
        }

        UIBezierPath *progressline = [_chartPath objectAtIndex:lineIndex];
        UIBezierPath *fillPath = [_fillPath objectAtIndex:lineIndex];
        UIBezierPath *pointPath = [_pointPath objectAtIndex:lineIndex];

        chartLine.path = progressline.CGPath;
        fillLayer.path = fillPath.CGPath;
        pointLayer.path = pointPath.CGPath;

        [CATransaction begin];

        [chartLine addAnimation:self.pathAnimation forKey:@"strokeEndAnimation"];
        chartLine.strokeEnd = 1.0;
        
        [fillLayer addAnimation:self.pathAnimation forKey:@"strokeEndAnimation"];
        
        // if you want cancel the point animation, conment this code, the point will show immediately
        if (chartData.inflexionPointStyle != PNLineChartPointStyleNone) {
            [pointLayer addAnimation:self.pathAnimation forKey:@"strokeEndAnimation"];
        }

        [CATransaction commit];

        NSMutableArray *textLayerArray = [self.gradeStringPaths objectAtIndex:lineIndex];
        for (CATextLayer *textLayer in textLayerArray) {
            CABasicAnimation *fadeAnimation = [self fadeAnimation];
            [textLayer addAnimation:fadeAnimation forKey:nil];
        }

        UIGraphicsEndImageContext();
    }
}


- (void)calculateChartPath:(NSMutableArray *)chartPath andFillPath:(NSMutableArray *)fillsPath andPointsPath:(NSMutableArray *)pointsPath andPathKeyPoints:(NSMutableArray *)pathPoints andPathStartEndPoints:(NSMutableArray *)pointsOfPath {

    // Draw each line
    for (NSUInteger lineIndex = 0; lineIndex < self.chartData.count; lineIndex++) {
        PNLineChartData *chartData = self.chartData[lineIndex];

        CGFloat yValue;
        CGFloat innerGrade;

        UIBezierPath *progressline = [UIBezierPath bezierPath];
        UIBezierPath *fillPath = [UIBezierPath bezierPath];
        UIBezierPath *pointPath = [UIBezierPath bezierPath];


        [chartPath insertObject:progressline atIndex:lineIndex];
        [fillsPath insertObject:fillPath atIndex:lineIndex];
        [pointsPath insertObject:pointPath atIndex:lineIndex];


        NSMutableArray *gradePathArray = [NSMutableArray array];
        [self.gradeStringPaths addObject:gradePathArray];

        NSMutableArray *linePointsArray = [[NSMutableArray alloc] init];
        NSMutableArray *lineStartEndFillsArray = [[NSMutableArray alloc] init];
        NSMutableArray *lineStartEndPointsArray = [[NSMutableArray alloc] init];
        int last_x = 0;
        int last_y = 0;
        NSMutableArray<NSDictionary<NSString *, NSValue *> *> *progrssLinePaths = [NSMutableArray new];
        CGFloat inflexionWidth = chartData.inflexionPointWidth;

        for (NSUInteger i = 0; i < chartData.itemCount; i++) {

            yValue = chartData.getData(i).y;

            // 计算item的y值对应坐标系的位置
            if (!(_yValueMax - _yValueMin)) {
                innerGrade = 0.5;
            } else {
                innerGrade = (yValue - _yValueMin) / (_yValueMax - _yValueMin);
            }

            int x =_chartMarginLeft + i * _xLabelWidth;

            int y = _chartMarginTop + _chartCavanHeight - (innerGrade * _chartCavanHeight);

        
            // Circular point
            if (chartData.inflexionPointStyle == PNLineChartPointStyleCircle) {

                CGRect circleRect = CGRectMake(x - inflexionWidth / 2, y - inflexionWidth / 2, inflexionWidth, inflexionWidth);
                CGPoint circleCenter = CGPointMake(circleRect.origin.x + (circleRect.size.width / 2), circleRect.origin.y + (circleRect.size.height / 2));

                [pointPath moveToPoint:CGPointMake(circleCenter.x + (inflexionWidth / 2), circleCenter.y)];
                [pointPath addArcWithCenter:circleCenter radius:inflexionWidth / 2 startAngle:0 endAngle:2 * M_PI clockwise:YES];

                //jet text display text
                if (chartData.showPointLabel) {
                    [gradePathArray addObject:[self createPointLabelFor:chartData.getData(i).rawY pointCenter:circleCenter width:inflexionWidth withChartData:chartData]];
                }

                if (i > 0) {

                    // calculate the point for line
                    float distance = sqrt(pow(x - last_x, 2) + pow(y - last_y, 2));
                    float last_x1 = last_x + (inflexionWidth / 2) / distance * (x - last_x);
                    float last_y1 = last_y + (inflexionWidth / 2) / distance * (y - last_y);
                    float x1 = x - (inflexionWidth / 2) / distance * (x - last_x);
                    float y1 = y - (inflexionWidth / 2) / distance * (y - last_y);

                    [progrssLinePaths addObject:@{@"from" : [NSValue valueWithCGPoint:CGPointMake(last_x1, last_y1)],
                            @"to" : [NSValue valueWithCGPoint:CGPointMake(x1, y1)]}];
                }
            }
                // Square point
            else if (chartData.inflexionPointStyle == PNLineChartPointStyleSquare) {

                CGRect squareRect = CGRectMake(x - inflexionWidth / 2, y - inflexionWidth / 2, inflexionWidth, inflexionWidth);
                CGPoint squareCenter = CGPointMake(squareRect.origin.x + (squareRect.size.width / 2), squareRect.origin.y + (squareRect.size.height / 2));

                [pointPath moveToPoint:CGPointMake(squareCenter.x - (inflexionWidth / 2), squareCenter.y - (inflexionWidth / 2))];
                [pointPath addLineToPoint:CGPointMake(squareCenter.x + (inflexionWidth / 2), squareCenter.y - (inflexionWidth / 2))];
                [pointPath addLineToPoint:CGPointMake(squareCenter.x + (inflexionWidth / 2), squareCenter.y + (inflexionWidth / 2))];
                [pointPath addLineToPoint:CGPointMake(squareCenter.x - (inflexionWidth / 2), squareCenter.y + (inflexionWidth / 2))];
                [pointPath closePath];

                // text display text
                if (chartData.showPointLabel) {
                    [gradePathArray addObject:[self createPointLabelFor:chartData.getData(i).rawY pointCenter:squareCenter width:inflexionWidth withChartData:chartData]];
                }

                if (i > 0) {

                    // calculate the point for line
                    float distance = sqrt(pow(x - last_x, 2) + pow(y - last_y, 2));
                    float last_x1 = last_x + (inflexionWidth / 2);
                    float last_y1 = last_y + (inflexionWidth / 2) / distance * (y - last_y);
                    float x1 = x - (inflexionWidth / 2);
                    float y1 = y - (inflexionWidth / 2) / distance * (y - last_y);

                    [progrssLinePaths addObject:@{@"from" : [NSValue valueWithCGPoint:CGPointMake(last_x1, last_y1)],
                            @"to" : [NSValue valueWithCGPoint:CGPointMake(x1, y1)]}];
                }
            }
                // Triangle point
            else if (chartData.inflexionPointStyle == PNLineChartPointStyleTriangle) {

                CGRect squareRect = CGRectMake(x - inflexionWidth / 2, y - inflexionWidth / 2, inflexionWidth, inflexionWidth);

                CGPoint startPoint = CGPointMake(squareRect.origin.x, squareRect.origin.y + squareRect.size.height);
                CGPoint endPoint = CGPointMake(squareRect.origin.x + (squareRect.size.width / 2), squareRect.origin.y);
                CGPoint middlePoint = CGPointMake(squareRect.origin.x + (squareRect.size.width), squareRect.origin.y + squareRect.size.height);

                [pointPath moveToPoint:startPoint];
                [pointPath addLineToPoint:middlePoint];
                [pointPath addLineToPoint:endPoint];
                [pointPath closePath];

                // text display text
                if (chartData.showPointLabel) {
                    [gradePathArray addObject:[self createPointLabelFor:chartData.getData(i).rawY pointCenter:middlePoint width:inflexionWidth withChartData:chartData]];
                }

                if (i > 0) {
                    // calculate the point for triangle
                    float distance = sqrt(pow(x - last_x, 2) + pow(y - last_y, 2)) * 1.4;
                    float last_x1 = last_x + (inflexionWidth / 2) / distance * (x - last_x);
                    float last_y1 = last_y + (inflexionWidth / 2) / distance * (y - last_y);
                    float x1 = x - (inflexionWidth / 2) / distance * (x - last_x);
                    float y1 = y - (inflexionWidth / 2) / distance * (y - last_y);

                    [progrssLinePaths addObject:@{@"from" : [NSValue valueWithCGPoint:CGPointMake(last_x1, last_y1)],
                            @"to" : [NSValue valueWithCGPoint:CGPointMake(x1, y1)]}];
                }
            }
            
            else {

                if (i > 0) {
                    [progrssLinePaths addObject:@{@"from" : [NSValue valueWithCGPoint:CGPointMake(last_x, last_y)],
                            @"to" : [NSValue valueWithCGPoint:CGPointMake(x, y)]}];
                }
            }
            [linePointsArray addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
            last_x = x;
            last_y = y;
        }

        
        if (self.showSmoothLines && chartData.itemCount >= 4) {
            [progressline moveToPoint:[progrssLinePaths[0][@"from"] CGPointValue]];
            for (NSDictionary<NSString *, NSValue *> *item in progrssLinePaths) {
                CGPoint p1 = [item[@"from"] CGPointValue];
                CGPoint p2 = [item[@"to"] CGPointValue];
                [progressline moveToPoint:p1];
                CGPoint midPoint = [PNLineChart midPointBetweenPoint1:p1 andPoint2:p2];
                [progressline addQuadCurveToPoint:midPoint
                                     controlPoint:[PNLineChart controlPointBetweenPoint1:midPoint andPoint2:p1]];
                [progressline addQuadCurveToPoint:p2
                                     controlPoint:[PNLineChart controlPointBetweenPoint1:midPoint andPoint2:p2]];
            }
        } else {
            for (NSDictionary<NSString *, NSValue *> *item in progrssLinePaths) {
                if (item[@"from"]) {
                    [progressline moveToPoint:[item[@"from"] CGPointValue]];
                    [lineStartEndPointsArray addObject:item[@"from"]];
                }
                if (item[@"to"]) {
                    [progressline addLineToPoint:[item[@"to"] CGPointValue]];
                    [lineStartEndPointsArray addObject:item[@"to"]];
                }
            }
        }
        [pathPoints addObject:[linePointsArray copy]];
        
        [pointsOfPath addObject:[lineStartEndPointsArray copy]];
        
        // fill Path
        CGPoint firstPoint = CGPointZero;
        CGPoint lastPoint = CGPointZero;
        
        for (int i=0; i<progrssLinePaths.count; i++) {
            NSDictionary<NSString *, NSValue *> *item = progrssLinePaths[i];
            
            if (i==0) {
                if (item[@"from"]) {
                    [fillPath moveToPoint:[item[@"from"] CGPointValue]];
                    [lineStartEndFillsArray addObject:item[@"from"]];
                    firstPoint = CGPointMake([item[@"from"] CGPointValue].x, _chartMarginTop + _chartCavanHeight);
                }
            }
            else if (i==progrssLinePaths.count-1) {
                [fillPath addLineToPoint:[item[@"from"] CGPointValue]];
                [fillPath addLineToPoint:[item[@"to"] CGPointValue]];
                lastPoint = CGPointMake([item[@"to"] CGPointValue].x, _chartMarginTop + _chartCavanHeight);
                [fillPath addLineToPoint:lastPoint];
                [fillPath addLineToPoint:firstPoint];
                [fillPath closePath];
            }
            else {
                if (item[@"from"]) {
                    [fillPath addLineToPoint:[item[@"from"] CGPointValue]];
                    [lineStartEndFillsArray addObject:item[@"from"]];
                }
            }
        }
    }
}

#pragma mark - Set Chart Data

- (void)setChartData:(NSArray *)data {
    if (data != _chartData) {

        // remove all shape layers before adding new ones
        for (CALayer *layer in self.chartLineArray) {
            [layer removeFromSuperlayer];
        }
        for (CALayer *layer in self.chartPointArray) {
            [layer removeFromSuperlayer];
        }
        for (CALayer *layer in self.chartFillArray) {
            [layer removeFromSuperlayer];
        }

        self.chartLineArray = [NSMutableArray arrayWithCapacity:data.count];
        self.chartPointArray = [NSMutableArray arrayWithCapacity:data.count];
        self.chartFillArray = [NSMutableArray arrayWithCapacity:data.count];
        
        for (PNLineChartData *chartData in data) {
            // create as many chart line layers as there are data-lines
            CAShapeLayer *chartLine = [CAShapeLayer layer];
            chartLine.lineCap = kCALineCapButt;
            chartLine.lineJoin = kCALineJoinMiter;
            chartLine.fillColor = [[UIColor whiteColor] CGColor];
            chartLine.lineWidth = chartData.lineWidth;
            chartLine.strokeEnd = 0.0;
            [self.layer addSublayer:chartLine];
            [self.chartLineArray addObject:chartLine];

            // create fill
            CAShapeLayer *fillLayer = [CAShapeLayer layer];
            fillLayer.strokeColor = nil;
            fillLayer.lineCap = kCALineCapRound;
            fillLayer.lineJoin = kCALineJoinBevel;
            fillLayer.fillColor = [[chartData.fillColor colorWithAlphaComponent:1.f] CGColor];
            fillLayer.opacity = 0.5;
            fillLayer.lineWidth = chartData.lineWidth;
            [self.layer addSublayer:fillLayer];
            [self.chartFillArray addObject:fillLayer];
            
            // create point
            CAShapeLayer *pointLayer = [CAShapeLayer layer];
            pointLayer.strokeColor = [[chartData.color colorWithAlphaComponent:chartData.alpha] CGColor];
            pointLayer.lineCap = kCALineCapRound;
            pointLayer.lineJoin = kCALineJoinBevel;
            pointLayer.fillColor = nil;
            pointLayer.lineWidth = chartData.lineWidth;
            [self.layer addSublayer:pointLayer];
            [self.chartPointArray addObject:pointLayer];
            
            
        }

        _chartData = data;

        [self prepareYLabelsWithData:data];
        // Cavan height and width needs to be set before
        // setNeedsDisplay is invoked because setNeedsDisplay
        // will invoke drawRect and if Cavan dimensions is not
        // set the chart will be misplaced
        if (!_showLabel) {
            _chartCavanHeight = self.frame.size.height - 2 * _yLabelHeight;
            _chartCavanWidth = self.frame.size.width;
            //_chartMargin = chartData.inflexionPointWidth;
            _xLabelWidth = (_chartCavanWidth / ([_xLabels count]));
        }
        [self setNeedsDisplay];
    }
}

- (void)prepareYLabelsWithData:(NSArray *)data {
    CGFloat yMax = 0.0f;
    CGFloat yMin = MAXFLOAT;
    NSMutableArray *yLabelsArray = [NSMutableArray new];

    for (PNLineChartData *chartData in data) {
        // create as many chart line layers as there are data-lines

        for (NSUInteger i = 0; i < chartData.itemCount; i++) {
            CGFloat yValue = chartData.getData(i).y;
            [yLabelsArray addObject:[NSString stringWithFormat:@"%2f", yValue]];
            yMax = fmaxf(yMax, yValue);
            yMin = fminf(yMin, yValue);
        }
    }


    // Min value for Y label
    if (yMax < 5) {
        yMax = 5.0f;
    }

    _yValueMin = (_yFixedValueMin > -FLT_MAX) ? _yFixedValueMin : yMin;
    _yValueMax = (_yFixedValueMax > -FLT_MAX) ? _yFixedValueMax : yMax + yMax / 10.0;

    if (_showGenYLabels) {
        [self setYLabels];
    }

}

#pragma mark - Update Chart Data

- (void)updateChartData:(NSArray *)data {
    _chartData = data;

    [self prepareYLabelsWithData:data];

    [self calculateChartPath:_chartPath andFillPath:_fillPath andPointsPath:_pointPath andPathKeyPoints:_pathPoints andPathStartEndPoints:_endPointsOfPath];

    for (NSUInteger lineIndex = 0; lineIndex < self.chartData.count; lineIndex++) {

        CAShapeLayer *chartLine = (CAShapeLayer *) self.chartLineArray[lineIndex];
        CAShapeLayer *fillLayer = (CAShapeLayer *) self.chartFillArray[lineIndex];
        CAShapeLayer *pointLayer = (CAShapeLayer *) self.chartPointArray[lineIndex];


        UIBezierPath *progressline = [_chartPath objectAtIndex:lineIndex];
        UIBezierPath *fillPath = [_fillPath objectAtIndex:lineIndex];
        UIBezierPath *pointPath = [_pointPath objectAtIndex:lineIndex];
        

        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        pathAnimation.fromValue = (id) chartLine.path;
        pathAnimation.toValue = (id) [progressline CGPath];
        pathAnimation.duration = 0.5f;
        pathAnimation.autoreverses = NO;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [chartLine addAnimation:pathAnimation forKey:@"animationKey"];

        CABasicAnimation *fillAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        fillAnimation.fromValue = (id) fillLayer.path;
        fillAnimation.toValue = (id) [fillPath CGPath];
        fillAnimation.duration = 0.5f;
        fillAnimation.autoreverses = NO;
        fillAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [fillLayer addAnimation:fillAnimation forKey:@"animationKey"];

        CABasicAnimation *pointPathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        pointPathAnimation.fromValue = (id) pointLayer.path;
        pointPathAnimation.toValue = (id) [pointPath CGPath];
        pointPathAnimation.duration = 0.5f;
        pointPathAnimation.autoreverses = NO;
        pointPathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [pointLayer addAnimation:pointPathAnimation forKey:@"animationKey"];

        chartLine.path = progressline.CGPath;
        fillLayer.path = fillPath.CGPath;
        pointLayer.path = pointPath.CGPath;


    }

}

#define IOS7_OR_LATER [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0
#pragma mark - 绘制 (x, y) 坐标轴
- (void)drawRect:(CGRect)rect {
    
    if (self.isShowCoordinateAxis) {
        CGFloat yAxisOffset = 0.f;

        CGContextRef ctx = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(ctx);
        CGContextSetLineWidth(ctx, self.axisWidth);
        CGContextSetStrokeColorWithColor(ctx, [self.axisColor CGColor]);

        CGFloat xAxisWidth = CGRectGetWidth(rect) - (_chartMarginLeft + _chartMarginRight);
        CGFloat yAxisHeight = CGRectGetHeight(rect) - (_chartMarginTop + _chartMarginBottom);

        // 绘制 左边 实心竖线✅
        CGContextMoveToPoint(ctx, _chartMarginLeft + yAxisOffset, _chartMarginTop);
        CGContextAddLineToPoint(ctx, _chartMarginLeft + yAxisOffset, _chartMarginTop + yAxisHeight);
        // 绘制 右边 实心竖线✅
        CGContextMoveToPoint(ctx, _chartMarginLeft + yAxisOffset + xAxisWidth, _chartMarginTop);
        CGContextAddLineToPoint(ctx, _chartMarginLeft + yAxisOffset + xAxisWidth, _chartMarginTop + yAxisHeight);
        CGContextStrokePath(ctx);


        if (self.showLabel) {
            // 绘制 x轴 的单位分割点✅
            CGPoint point;
            for (NSUInteger i = 0; i < [self.xLabels count]; i++) {
                point = CGPointMake(_chartMarginLeft + yAxisOffset + (i * _xLabelWidth), _chartMarginTop + _chartCavanHeight);
                CGContextMoveToPoint(ctx, point.x, point.y - 2);
                CGContextAddLineToPoint(ctx, point.x, point.y);
                CGContextStrokePath(ctx);
            }

        }

        UIFont *font = [UIFont systemFontOfSize:11];

        // 绘制 y轴 的单位
        if ([self.yUnit length]) {
            CGFloat height = [PNLineChart sizeOfString:self.yUnit withWidth:30.f font:font].height;
            CGRect drawRect = CGRectMake(_chartMarginLeft + 10 + 5, 0, 30.f, height);
            [self drawTextInContext:ctx text:self.yUnit inRect:drawRect font:font];
        }

        // 绘制 x轴 的单位
        if ([self.xUnit length]) {
            CGFloat height = [PNLineChart sizeOfString:self.xUnit withWidth:30.f font:font].height;
            CGRect drawRect = CGRectMake(CGRectGetWidth(rect) - _chartMarginLeft + 5, _chartMarginBottom + _chartCavanHeight - height / 2, 25.f, height);
            [self drawTextInContext:ctx text:self.xUnit inRect:drawRect font:font];
        }
    }
    
    // 绘制 y轴 等高线✅
    if (self.showYGridLines) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGFloat yAxisOffset = _showLabel ? 0.f : 0.0f;
        CGPoint point;
        CGFloat yStepHeight = _chartCavanHeight / _yLabelNum;
        if (self.yGridLinesColor) {
            CGContextSetStrokeColorWithColor(ctx, self.yGridLinesColor.CGColor);
        } else {
            CGContextSetStrokeColorWithColor(ctx, [UIColor lightGrayColor].CGColor);
        }
        for (NSUInteger i = 0; i <= _yLabelNum; i++) {
            point = CGPointMake(_chartMarginLeft + yAxisOffset, (_chartMarginTop + _chartCavanHeight - i * yStepHeight));
            CGContextMoveToPoint(ctx, point.x, point.y);
            // 设置虚线的疏密程度
            CGFloat dash[] = {3, 4};
            // dot diameter is 20 points
            CGContextSetLineWidth(ctx, 1.0);
            CGContextSetLineCap(ctx, kCGLineCapRound);
            CGContextSetLineDash(ctx, 0.0, dash, 2);
            CGContextAddLineToPoint(ctx, CGRectGetWidth(rect) - _chartMarginRight, point.y);
            CGContextStrokePath(ctx);
        }
    }

    [super drawRect:rect];
}

#pragma mark - 内部初始化函数

- (void)setupDefaultValues {
    [super setupDefaultValues];
    // Initialization code
    self.backgroundColor = [UIColor whiteColor];
    self.clipsToBounds = YES;
    self.chartLineArray = [NSMutableArray new];
    _showLabel = YES;
    _showGenYLabels = YES;
    _pathPoints = [[NSMutableArray alloc] init];
    _endPointsOfPath = [[NSMutableArray alloc] init];
    self.userInteractionEnabled = YES;

    _yFixedValueMin = -FLT_MAX;
    _yFixedValueMax = -FLT_MAX;
    _yLabelNum = 5.0;
    _yLabelHeight = [[[[PNChartLabel alloc] init] font] pointSize];

//    _chartMargin = 40;

    _chartMarginLeft = 17.0;
    _chartMarginRight = 17.0;
    _chartMarginTop = 40.0;
    _chartMarginBottom = 36.0;

    _yLabelFormat = @"%1.f";

    _chartCavanWidth = self.frame.size.width - _chartMarginLeft - _chartMarginRight;
    _chartCavanHeight = self.frame.size.height - _chartMarginBottom - _chartMarginTop;

    // Coordinate Axis Default Values
    _showCoordinateAxis = NO;
    _axisColor = UIColorFromRGB(0xd9d9d9);// x, y轴的颜色
    _axisWidth = 1.f;

    // do not create curved line chart by default
    _showSmoothLines = NO;

}


#pragma mark - 简单的初始化API方法
- (void)setLineChartModelArray:(NSArray *)modelArray {
    if (modelArray != nil) {
        _chartModelArray = [modelArray mutableCopy];
    }
    
    {
        NSMutableArray *xStringArr = [NSMutableArray array];
        for (NSInteger i=0; i<_chartModelArray.count; i++) {
            PNLineChartDataModel *temp = _chartModelArray[i];
            [xStringArr addObject:temp.xString];
        }
        
        self.xLabels = xStringArr;
    }
    
    NSMutableArray *yValueArr = [NSMutableArray array];
    for (NSInteger i=0; i<_chartModelArray.count; i++) {
        PNLineChartDataModel *temp = _chartModelArray[i];
        NSNumber *yNum = [NSNumber numberWithFloat:temp.yValue];
        [yValueArr addObject:yNum];
    }
    
    PNLineChartData *data = [PNLineChartData new];
    data.color = UIColorFromRGB(0x3d99ed);
    data.fillColor = UIColorFromRGB(0xdceeff);
    data.itemCount = yValueArr.count;
    data.getData = ^(NSUInteger index) {
        CGFloat yValue = [yValueArr[index] floatValue];
        return [PNLineChartDataItem dataItemWithY:yValue];
    };
    
    self.chartData = @[data];
    [self strokeChart];
    
}

#pragma mark - Tools func

+ (CGSize)sizeOfString:(NSString *)text withWidth:(float)width font:(UIFont *)font {
    CGSize size = CGSizeMake(width, MAXFLOAT);

    if ([text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSDictionary *tdic = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
        size = [text boundingRectWithSize:size
                                  options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                               attributes:tdic
                                  context:nil].size;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        size = [text sizeWithFont:font constrainedToSize:size lineBreakMode:NSLineBreakByCharWrapping];
#pragma clang diagnostic pop
    }

    return size;
}

+ (CGPoint)midPointBetweenPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2 {
    return CGPointMake((point1.x + point2.x) / 2, (point1.y + point2.y) / 2);
}

+ (CGPoint)controlPointBetweenPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2 {
    CGPoint controlPoint = [self midPointBetweenPoint1:point1 andPoint2:point2];
    CGFloat diffY = abs((int) (point2.y - controlPoint.y));
    if (point1.y < point2.y)
        controlPoint.y += diffY;
    else if (point1.y > point2.y)
        controlPoint.y -= diffY;
    return controlPoint;
}

- (void)drawTextInContext:(CGContextRef)ctx text:(NSString *)text inRect:(CGRect)rect font:(UIFont *)font {
    if (IOS7_OR_LATER) {
        NSMutableParagraphStyle *priceParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        priceParagraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        priceParagraphStyle.alignment = NSTextAlignmentLeft;

        [text drawInRect:rect
          withAttributes:@{NSParagraphStyleAttributeName : priceParagraphStyle, NSFontAttributeName : font}];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [text drawInRect:rect
                withFont:font
           lineBreakMode:NSLineBreakByTruncatingTail
               alignment:NSTextAlignmentLeft];
#pragma clang diagnostic pop
    }
}

- (NSString *)formatYLabel:(double)value {

    if (self.yLabelBlockFormatter) {
        return self.yLabelBlockFormatter(value);
    }
    else {
        if (!self.thousandsSeparator) {
            NSString *format = self.yLabelFormat ?: @"%1.f";
            return [NSString stringWithFormat:format, value];
        }

        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        return [numberFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
    }
}

- (UIView *)getLegendWithMaxWidth:(CGFloat)mWidth {
    if ([self.chartData count] < 1) {
        return nil;
    }

    /* This is a short line that refers to the chart data */
    CGFloat legendLineWidth = 40;

    /* x and y are the coordinates of the starting point of each legend item */
    CGFloat x = 0;
    CGFloat y = 0;

    /* accumulated height */
    CGFloat totalHeight = 0;
    CGFloat totalWidth = 0;

    NSMutableArray *legendViews = [[NSMutableArray alloc] init];

    /* Determine the max width of each legend item */
    CGFloat maxLabelWidth;
    if (self.legendStyle == PNLegendItemStyleStacked) {
        maxLabelWidth = mWidth - legendLineWidth;
    } else {
        maxLabelWidth = MAXFLOAT;
    }

    /* this is used when labels wrap text and the line
     * should be in the middle of the first row */
    CGFloat singleRowHeight = [PNLineChart sizeOfString:@"Test"
                                              withWidth:MAXFLOAT
                                                   font:self.legendFont ? self.legendFont : [UIFont systemFontOfSize:12.0f]].height;

    NSUInteger counter = 0;
    NSUInteger rowWidth = 0;
    NSUInteger rowMaxHeight = 0;

    for (PNLineChartData *pdata in self.chartData) {
        /* Expected label size*/
        CGSize labelsize = [PNLineChart sizeOfString:pdata.dataTitle
                                           withWidth:maxLabelWidth
                                                font:self.legendFont ? self.legendFont : [UIFont systemFontOfSize:12.0f]];

        /* draw lines */
        if ((rowWidth + labelsize.width + legendLineWidth > mWidth) && (self.legendStyle == PNLegendItemStyleSerial)) {
            rowWidth = 0;
            x = 0;
            y += rowMaxHeight;
            rowMaxHeight = 0;
        }
        rowWidth += labelsize.width + legendLineWidth;
        totalWidth = self.legendStyle == PNLegendItemStyleSerial ? fmaxf(rowWidth, totalWidth) : fmaxf(totalWidth, labelsize.width + legendLineWidth);

        /* If there is inflection decorator, the line is composed of two lines
         * and this is the space that separates two lines in order to put inflection
         * decorator */

        CGFloat inflexionWidthSpacer = pdata.inflexionPointStyle == PNLineChartPointStyleTriangle ? pdata.inflexionPointWidth / 2 : pdata.inflexionPointWidth;

        CGFloat halfLineLength;

        if (pdata.inflexionPointStyle != PNLineChartPointStyleNone) {
            halfLineLength = (legendLineWidth * 0.8 - inflexionWidthSpacer) / 2;
        } else {
            halfLineLength = legendLineWidth * 0.8;
        }

        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(x + legendLineWidth * 0.1, y + (singleRowHeight - pdata.lineWidth) / 2, halfLineLength, pdata.lineWidth)];

        line.backgroundColor = pdata.color;
        line.alpha = pdata.alpha;
        [legendViews addObject:line];

        if (pdata.inflexionPointStyle != PNLineChartPointStyleNone) {
            line = [[UIView alloc] initWithFrame:CGRectMake(x + legendLineWidth * 0.1 + halfLineLength + inflexionWidthSpacer, y + (singleRowHeight - pdata.lineWidth) / 2, halfLineLength, pdata.lineWidth)];
            line.backgroundColor = pdata.color;
            line.alpha = pdata.alpha;
            [legendViews addObject:line];
        }

        // Add inflexion type
        UIColor *inflexionPointColor = pdata.inflexionPointColor;
        if (!inflexionPointColor) {
            inflexionPointColor = pdata.color;
        }
        [legendViews addObject:[self drawInflexion:pdata.inflexionPointWidth
                                            center:CGPointMake(x + legendLineWidth / 2, y + singleRowHeight / 2)
                                       strokeWidth:pdata.lineWidth
                                    inflexionStyle:pdata.inflexionPointStyle
                                          andColor:inflexionPointColor
                                          andAlpha:pdata.alpha]];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x + legendLineWidth, y, labelsize.width, labelsize.height)];
        label.text = pdata.dataTitle;
        label.textColor = self.legendFontColor ? self.legendFontColor : [UIColor blackColor];
        label.font = self.legendFont ? self.legendFont : [UIFont systemFontOfSize:12.0f];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;

        rowMaxHeight = fmaxf(rowMaxHeight, labelsize.height);
        x += self.legendStyle == PNLegendItemStyleStacked ? 0 : labelsize.width + legendLineWidth;
        y += self.legendStyle == PNLegendItemStyleStacked ? labelsize.height : 0;


        totalHeight = self.legendStyle == PNLegendItemStyleSerial ? fmaxf(totalHeight, rowMaxHeight + y) : totalHeight + labelsize.height;

        [legendViews addObject:label];
        counter++;
    }

    UIView *legend = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mWidth, totalHeight)];

    for (UIView *v in legendViews) {
        [legend addSubview:v];
    }
    return legend;
}


- (UIImageView *)drawInflexion:(CGFloat)size center:(CGPoint)center strokeWidth:(CGFloat)sw inflexionStyle:(PNLineChartPointStyle)type andColor:(UIColor *)color andAlpha:(CGFloat)alfa {
    //Make the size a little bigger so it includes also border stroke
    CGSize aSize = CGSizeMake(size + sw, size + sw);


    UIGraphicsBeginImageContextWithOptions(aSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();


    if (type == PNLineChartPointStyleCircle) {
        CGContextAddArc(context, (size + sw) / 2, (size + sw) / 2, size / 2, 0, M_PI * 2, YES);
    } else if (type == PNLineChartPointStyleSquare) {
        CGContextAddRect(context, CGRectMake(sw / 2, sw / 2, size, size));
    } else if (type == PNLineChartPointStyleTriangle) {
        CGContextMoveToPoint(context, sw / 2, size + sw / 2);
        CGContextAddLineToPoint(context, size + sw / 2, size + sw / 2);
        CGContextAddLineToPoint(context, size / 2 + sw / 2, sw / 2);
        CGContextAddLineToPoint(context, sw / 2, size + sw / 2);
        CGContextClosePath(context);
    }

    //Set some stroke properties
    CGContextSetLineWidth(context, sw);
    CGContextSetAlpha(context, alfa);
    CGContextSetStrokeColorWithColor(context, color.CGColor);

    //Finally draw
    CGContextDrawPath(context, kCGPathStroke);

    //now get the image from the context
    UIImage *squareImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    //// Translate origin
    CGFloat originX = center.x - (size + sw) / 2.0;
    CGFloat originY = center.y - (size + sw) / 2.0;

    UIImageView *squareImageView = [[UIImageView alloc] initWithImage:squareImage];
    [squareImageView setFrame:CGRectMake(originX, originY, size + sw, size + sw)];
    return squareImageView;
}

#pragma mark setter and getter

- (CATextLayer *)createPointLabelFor:(CGFloat)grade pointCenter:(CGPoint)pointCenter width:(CGFloat)width withChartData:(PNLineChartData *)chartData {
    CATextLayer *textLayer = [[CATextLayer alloc] init];
    [textLayer setAlignmentMode:kCAAlignmentCenter];
    [textLayer setForegroundColor:[chartData.pointLabelColor CGColor]];
    [textLayer setBackgroundColor:[[[UIColor whiteColor] colorWithAlphaComponent:0.8] CGColor]];
    [textLayer setCornerRadius:textLayer.fontSize / 8.0];

    if (chartData.pointLabelFont != nil) {
        [textLayer setFont:(__bridge CFTypeRef) (chartData.pointLabelFont)];
        textLayer.fontSize = [chartData.pointLabelFont pointSize];
    }

    CGFloat textHeight = textLayer.fontSize * 1.1;
    CGFloat textWidth = width * 8;
    CGFloat textStartPosY;

    textStartPosY = pointCenter.y - textLayer.fontSize;

    [self.layer addSublayer:textLayer];

    if (chartData.pointLabelFormat != nil) {
        [textLayer setString:[[NSString alloc] initWithFormat:chartData.pointLabelFormat, grade]];
    } else {
        [textLayer setString:[[NSString alloc] initWithFormat:_yLabelFormat, grade]];
    }

    [textLayer setFrame:CGRectMake(0, 0, textWidth, textHeight)];
    [textLayer setPosition:CGPointMake(pointCenter.x, textStartPosY)];
    textLayer.contentsScale = [UIScreen mainScreen].scale;

    return textLayer;
}

- (CABasicAnimation *)fadeAnimation {
    CABasicAnimation *fadeAnimation = nil;
    if (self.displayAnimated) {
        fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeAnimation.fromValue = [NSNumber numberWithFloat:0.0];
        fadeAnimation.toValue = [NSNumber numberWithFloat:1.0];
        fadeAnimation.duration = 2.0;
    }
    return fadeAnimation;
}

- (CABasicAnimation *)pathAnimation {
    if (self.displayAnimated && !_pathAnimation) {
        _pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        _pathAnimation.duration = 1.0;
        _pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        _pathAnimation.fromValue = @0.0f;
        _pathAnimation.toValue = @1.0f;
    }
    return _pathAnimation;
}

@end
