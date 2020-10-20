classdef Linkage < handle
    %POINTSET Summary of this class goes here
    %   Detailed explanation goes here
    properties
        X=zeros(2,0)
        E=zeros(2,0)
        crank=[];
        Clickable
    end
    properties(SetAccess = private)
        DragStartPoint
        isDragged
        DraggedPointID
        Xi
    end
    properties(Access = private)
        hPoints
        hEdges
        hArrow
        Elines
        hFig
        hTempEdge
        CID_onMouseDrag
        CID_onMouseUp
        CID_onEdgeDrag
        hSnap
    end
    
    methods
        function obj = Linkage(varargin)
            obj.hEdges=line('XData',obj.X(1,:),'YData',obj.X(2,:),'LineStyle','-',...
                        'ButtonDownFcn',@(src,ev)onEdgeMouseButtonDown(obj,src,ev));
            obj.hPoints=line('XData',obj.X(1,:),'YData',obj.X(2,:),varargin{:},...
                        'ButtonDownFcn',@(src,ev)onPointMouseButtonDown(obj,src,ev));
            obj.hTempEdge=line('XData',[],'YData',[],'LineStyle','-');
            hold on
            obj.hArrow=quiver(1,1,1,1);
            set(obj.hArrow,'Marker','o','LineWidth',4,'HitTest','off','Visible','off');

            obj.hFig=gcf;
            obj.hSnap=[];
            obj.Clickable=true;
        end
        function delete(obj)
            if ishandle(obj.hPoints)
                delete(obj.hPoints);
            end
        end
        function set.Clickable(obj,flag)
            if flag
                obj.hPoints.HitTest='on';
            else
                obj.hPoints.HitTest='off';
            end
        end
        function refresh(obj)
            % set points
            set(obj.hPoints,'XData',obj.X(1,:)','YData',obj.X(2,:)');
            % set edges
            delete(obj.hEdges);
            X=obj.X;
            E=obj.E;
            crank=obj.crank;
            obj.hEdges=plot([X(1,E(1,:));X(1,E(2,:))],[X(2,E(1,:));X(2,E(2,:))],'black',...
                      'ButtonDownFcn',@(src,ev)onEdgeMouseButtonDown(obj,src,ev),'UserData',[1;2]);
            if ~isempty(obj.crank)
                x1=X(:,crank(1));
                x2=X(:,crank(2));
                set(obj.hArrow,'XData',x1(1),'YData',x1(2),'UData',x2(1)-x1(1),'VData',x2(2)-x1(2),'Visible','on');
            else
                set(obj.hArrow,'Visible','off');
            end
                
            t=num2cell(obj.E,1);
            [obj.hEdges.UserData]=t{:};
            uistack(obj.hPoints, 'top')
        end
        function Fi=AddPoint(obj,X_new)
            if ~isempty(obj.hSnap)
                [pout,vout,viout,pfactor,facevout] = vertexpicker(obj.h_snap,[X_new',100;X_new',-100],'-force');
                X_new=mean(facevout(1:2,:),2);
                Fi=pfactor.FaceIndex;
            end
            obj.X=[obj.X, X_new];
            Fi=size(obj.X,2);
            obj.refresh;
        end
        function RemovePoint(obj,Xi_remove)
            obj.X(:,Xi_remove)=[];
            obj.E(:,any(obj.E==Xi_remove,1))=[];
            obj.E(obj.E>Xi_remove)=obj.E(obj.E>Xi_remove)-1;
            obj.refresh;
            notify(obj,'PointRemoved');
        end
        function Clear(obj)
            obj.X=zeros(2,0);
        end
        function Visible(obj,flag)
            set(obj.h_pointSet,'Visible',flag);
        end
        function SetSnap(obj,hSnap)
            obj.hSnap=hSnap;
        end
        function ClearSnap(obj)
            obj.hSnap=[];
        end
        function onPointMouseButtonDown(obj,src,ev)
            obj.DragStartPoint=get(gca,'currentpoint');
            obj.DragStartPoint=obj.DragStartPoint(1,1:2)';
            [~,obj.Xi]=min(sum((obj.X-repmat(obj.DragStartPoint,1,size(obj.X,2))).^2,1));
            obj.DraggedPointID=obj.Xi;
            switch get(gcf,'selectionType')
                case {'normal','alt'}
                    obj.CID_onMouseUp=iptaddcallback(obj.hFig,'WindowButtonUpFcn',@(src,ev)onPointMouseUp(obj,src,ev));
                    obj.CID_onMouseDrag=iptaddcallback(obj.hFig,'WindowButtonMotionFcn',@(src,ev)onPointDrag(obj,src,ev));
                    obj.isDragged=true;
                case 'extend'
                    obj.CID_onMouseUp=iptaddcallback(obj.hFig,'WindowButtonUpFcn',@(src,ev)onMouseEdgeUp(obj,src,ev));
                    obj.CID_onMouseDrag=iptaddcallback(obj.hFig,'WindowButtonMotionFcn',@(src,ev)onEdgeDrag(obj,src,ev));
                    obj.isDragged=true;
                case 'open' %double click
                    obj.RemovePoint(obj.Xi);
            end
            notify(obj,'PointPicked');
        end
        function onPointMouseUp(obj,src,ev)
            if ~isempty(obj.hSnap)
                down_pos=get(gca,'currentpoint');
                [~,X,V,~] = vertexpicker(obj.hSnap,down_pos,'-force');
                obj.X(:,obj.Xi)=X(1:2)';
            end
            iptremovecallback(obj.hFig,'WindowButtonUpFcn',obj.CID_onMouseUp);
            iptremovecallback(obj.hFig,'WindowButtonMotionFcn',obj.CID_onMouseDrag);
            notify(obj,'PointDropped');
            obj.isDragged=false;
            obj.DraggedPointID=[];
            obj.DragStartPoint=[];
        end
        function onPointDrag(obj,src,ev)
            down_pos=get(gca,'currentpoint');
            switch get(gcf,'selectionType')
                case 'normal'
                    obj.X(:,obj.Xi)=down_pos(1,1:2)';
                case 'alt'  % in windows this is 'control'
%                     obj.DragStartPoint=down_pos;
            end
            obj.refresh;
            notify(obj,'PointDragged');
        end
        function onEdgeMouseButtonDown(obj,src,ev)
            switch get(gcf,'selectionType')
                case 'open' %double click
                    obj.E(:,ismember(obj.E',src.UserData','rows'))=[];
                case 'alt'  % in windows this is 'control'
                    crank=obj.crank;
                    if isempty(crank)
                        crank=src.UserData;
                    elseif all(crank==src.UserData)
                        crank=[crank(2);crank(1)];
                    elseif crank(2)==src.UserData(1) & crank(1)==src.UserData(2)
                        crank=[];
                    else
                        crank=src.UserData;
                    end
                    obj.crank=crank;
            end
            obj.refresh;
        end
        function onEdgeDrag(obj,src,ev)
            [x,y]=obj.getEdgeOnMouseMove;
            obj.hTempEdge.XData = x;
            obj.hTempEdge.YData = y;
            notify(obj,'PointDragged');
        end
        function onMouseEdgeUp(obj,src,ev)
            iptremovecallback(obj.hFig,'WindowButtonUpFcn',obj.CID_onMouseUp);
            iptremovecallback(obj.hFig,'WindowButtonMotionFcn',obj.CID_onMouseDrag);
            notify(obj,'PointDropped');
            [x,y,ind]=obj.getEdgeOnMouseMove;
            if numel(ind)==2 && ~any(ismember(obj.E',ind','rows'))
                notify(obj,'EdgeAdded');
                obj.E(:,end+1)=ind;
            end
            obj.hTempEdge.XData=[];
            obj.hTempEdge.YData=[];

            obj.isDragged=false;
            obj.DraggedPointID=[];
            obj.DragStartPoint=[];
            obj.refresh;
        end
        function [x,y,ind]=getEdgeOnMouseMove(obj)
            x1=get(gca,'currentpoint');
            x2=obj.X(:,obj.Xi);
            [~,X,V,~] = vertexpicker(obj.hPoints,x1,'-force');
            x1=[x1(1,1);x1(1,2)];;
            xsnap=X(1:2)';
            if norm(x1-xsnap)<0.2 && obj.Xi~=V
                x1=xsnap;
                ind=[obj.Xi;V];
            else
                ind=obj.Xi;
            end
            x=[x1(1),x2(1)];
            y=[x1(2),x2(2)];
        end
    end
    events
        PointPicked
        PointDragged
        PointDropped
        PointRemoved
        EdgeAdded
    end
end



