function ass4 ()
  a = imread("image_1.jpg");
  b = imread("image_2.jpg");
  imshow(a);
  first = get_points;
  imshow(b);
  second = get_points;

  first_x = first(1, :);
  first_y = first(2, :);
  second_x = second(1, :);
  second_y = second(2, :);

  #EXAMPLE POINTS because ginput not working
  #first_x = [1321.1   1217.8   1284.2   1298.9   1236.3   1387.4   1092.5   1346.9];
  #first_y = [450.51   454.20   520.56   561.11   561.11   785.99   785.99   325.16];
  #second_x = [871.28   764.37   801.24   838.10   782.80   963.45   716.44   922.90];
  #second_y = [443.14   443.14   516.87   557.42   550.05   785.99   763.87   310.42];
  
  
  # -----------normalizing image points----------------
  tx_first = mean(first_x);
  ty_first = mean(first_y);
  tx_second = mean(second_x);
  ty_second = mean(second_y);
  
  first_x_cond = first_x - tx_first;
  first_y_cond = first_y - ty_first;
  second_x_cond = second_x - tx_second;
  second_y_cond = second_y - ty_second;
  
  sx_first = mean(abs(first_x_cond));
  sy_first = mean(abs(first_y_cond));
  sx_second = mean(abs(second_x_cond));
  sy_second = mean(abs(second_y_cond));
  
  first_x_cond = first_x_cond/sx_first;
  first_y_cond = first_y_cond/sy_first;
  second_x_cond = second_x_cond/sx_second;
  second_y_cond = second_y_cond/sy_second;
  
  first = [first_x_cond; first_y_cond];
  second = [second_x_cond; second_y_cond];
  # --------------Formulating a homogeneous linear equation----------
  a = [];
  for i = 1 : size(first, 2)
    temp = [first(1,i)*second(1,i) first(2,i)*second(1,i) second(1,i) first(1,i)*second(2,i) first(2,i)*second(2,i) second(2,i) first(1,i) first(2,i) 1];
    a = [a;temp];
    end
   # --------------SVD----------
  [u,s,v] = svd(a);
  f = v(:,9);
  f = transpose(reshape(f,3,3));
  
  t_first = CreateTransformationMatrix(tx_first,ty_first,sx_first,sy_first);
  t_second = CreateTransformationMatrix(tx_second,ty_second,sx_second,sy_second);
  
 
  # --------- Enforcing the internal constraint ----------------
  [u,s,v] = svd(f);
  s(3,3) = 0;
    
  f = u * s * transpose(v);
  
  f = transpose(t_second) * f;
  f = f * t_first;
  
  d = det(f)
  
  #------ geometric_error ----------
  geometric_error = geom_dist(f, first_x, first_y, second_x, second_y)
  
  #---- draw epipolar lines-------

  a = imread("image_1.jpg");
  figure, imshow(a), hold on 
  for point_number = 1:8
    point = [first_x(point_number), first_y(point_number), 1];
    corr_point = [second_x(point_number), second_y(point_number), 1];
    epipolar_line_T =  transpose(f) * transpose(corr_point);
    hline(epipolar_line_T); 
  end
  
  b = imread("image_2.jpg");
  figure, imshow(b), hold on 
  for point_number = 1:8
    point = [first_x(point_number), first_y(point_number), 1];
    corr_point = [second_x(point_number), second_y(point_number), 1];
    epipolar_line = f * transpose(point);
    hline(epipolar_line);
  end
  
endfunction

function sum = geom_dist(f, first_x, first_y, second_x, second_y)
  sum = 0;
  for point_number = 1:8
    point = [first_x(point_number), first_y(point_number), 1];
    corr_point = [second_x(point_number), second_y(point_number), 1];
    epipolar_line = f * transpose(point);
    epipolar_line_T =  transpose(f) * transpose(corr_point) ;
    gd = dist(epipolar_line, corr_point)^2 + dist(epipolar_line_T,point)^2;
    sum = sum + gd;
  end
endfunction

function d = dist(l,p)
  d = (l(1)*p(1)+l(2)*p(2)+l(3)*p(3))/(p(2)*sqrt(l(1)^2+l(2)^2));
endfunction

function norm_mat = normalize_image_points(x)

# Calculate center of mass
centroid = mean(x,2);

# Calculate distances of each point to the centroid
dist = sqrt(sum((x - centroid) .^ 2));

# Calculate current mean distance
mean_dist = mean(dist);

#shift the image coordinate systems to the respective centroids
#point coodinates in new cos: (x – centoid-x, y – centroid-y)
x = x-centroid;

# scale so that the mean distance from the origin to a point equals sqrt(2)
#multiplying old coordinates by sqrt(2) and dividing out the mean distance
norm_mat = x * sqrt(2) / mean_dist;


end


function t = CreateTransformationMatrix(tx, ty, sx, sy)
  t_scale = eye(3);
  t_scale(1,1) = 1/sx;
  t_scale(2,2) = 1/sy;
  
  t_translate = eye(3);
  t_translate(1,3) = -tx;
  t_translate(2,3) = -ty;
  
  t = t_scale*t_translate;
endfunction

function p = get_points
  p = [];
  but = 1;
  while but == 1
      [x, y, but] = ginput(1);
      if but == 1
        p = [p [x y 1]'];
        hold on;
        plot (x, y, 'r+');
        hold off;
      end
  end
endfunction

function  h = hline (l, varargin)
%        ==================
    if abs(l(1)) < abs(l(2))                                  % More horizontal
        xlim = get(get(gcf, 'CurrentAxes'), 'Xlim');
        x1 = cross(l, [1; 0; -xlim(1)]);
        x2 = cross(l, [1; 0; -xlim(2)]);
    else                                                        % More vertical
        ylim = get(get(gcf, 'CurrentAxes'), 'Ylim');
        x1 = cross(l, [0; 1; -ylim(1)]);
        x2 = cross(l, [0; 1; -ylim(2)]);
    end
    x1 = x1 / x1(3);
    x2 = x2 / x2(3);
    h = line([x1(1) x2(1)], [x1(2) x2(2)], varargin{:});
end

    



