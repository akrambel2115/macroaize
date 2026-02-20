import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/screens/RecipesScreen/recipes_controller.dart';
import 'package:macroaize/widgets/recipe_card.dart';
import 'package:macroaize/widgets/shared_search_bar.dart';

class RecipesView extends StatefulWidget {
  const RecipesView({super.key});

  @override
  State<RecipesView> createState() => _RecipesViewState();
}

class _RecipesViewState extends State<RecipesView> {
  final FocusNode _searchFocusNode = FocusNode();
  late final TextEditingController _searchController;

  // search active state
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _searchController.addListener(_onSearchTextChange);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchController.removeListener(_onSearchTextChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    final isFocused = _searchFocusNode.hasFocus;
    if (isFocused != _isSearching) {
      setState(() => _isSearching = isFocused);
    }
  }

  void _onSearchTextChange() {
    final hasText = _searchController.text.isNotEmpty;
    if (hasText != _isSearching) {
      setState(() => _isSearching = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure a shared RecipesController is registered; use it without re-initializing
    if (!Get.isRegistered<RecipesController>()) {
      Get.put(RecipesController());
    }
    return GetBuilder<RecipesController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(context),
          body: RefreshIndicator(
            onRefresh: () => controller.refreshRecipes(),
            color: AppColor.primaryOrange,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom + 64,
              ),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                cacheExtent: 1000,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeader(context, controller),
                        const SizedBox(height: 24),
                        // hide when searching
                        if (!_isSearching) ...[
                          _buildTopRecipesHorizontal(context, controller),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'all_recipes'.tr,
                          style: context.theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                  // all recipes grid
                  if (controller.isLoading && controller.allRecipes.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: _buildLoadingSliverGrid(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: _buildRecipeSliverGrid(
                        controller.allRecipes,
                        controller,
                        context,
                      ),
                    ),
                  // pagination controls
                  SliverToBoxAdapter(
                    child: _buildPaginationControls(context, controller),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final args = Get.arguments;
    final bool explicitShowBack = args is Map && args['showBack'] == true;
    final bool explicitHideBack = args is Map && args['hideBack'] == true;

    bool isInIndexedStack = false;
    context.visitAncestorElements((element) {
      if (element.widget is IndexedStack) {
        isInIndexedStack = true;
        return false;
      }
      return true;
    });

    final bool showBack =
        explicitShowBack && !explicitHideBack && !isInIndexedStack;

    return AppBar(
      scrolledUnderElevation: 0,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      automaticallyImplyLeading: showBack,
      title: Text(
        'recipes_title'.tr,
        style: context.theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      leading:
          showBack
              ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: context.theme.colorScheme.onSurface,
                ),
                onPressed: () => Get.back(),
              )
              : null,
    );
  }

  Widget _buildHeader(BuildContext context, RecipesController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'top_recipes_subtitle'.tr,
          style: context.theme.textTheme.bodyLarge?.copyWith(
            color: AppColor.neutralGrey600,
          ),
        ),
        const SizedBox(height: 12),
        SharedSearchBar(
          controller: _searchController,
          hint: 'Search recipes by name or ingredient'.tr,
          onChanged: (v) => controller.filterRecipes(v),
          onSubmitted: (v) => controller.filterRecipes(v, immediate: true),
          onClear: () {
            _searchController.clear();
            controller.filterRecipes('', immediate: true);
          },
          focusNode: _searchFocusNode,
        ),
      ],
    );
  }

  Widget _buildTopRecipesHorizontal(
    BuildContext context,
    RecipesController controller,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'top_recipes'.tr,
          style: context.theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child:
              controller.isLoading && controller.topRecipes.isEmpty
                  ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder:
                        (context, index) => SizedBox(
                          width: 160,
                          child: _buildLoadingCard(context),
                        ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemExtent: 160,
                    itemCount: controller.topRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = controller.topRecipes[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right:
                              index == controller.topRecipes.length - 1
                                  ? 0
                                  : 12,
                        ),
                        child: RepaintBoundary(
                          child: SizedBox(
                            width: 160,
                            child: RecipeCard(
                              recipe: recipe,
                              onTap: () => controller.openRecipeDetails(recipe),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  // sliver grid builder
  SliverGrid _buildRecipeSliverGrid(
    List recipes,
    RecipesController controller,
    BuildContext context,
  ) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final recipe = recipes[index];
          return RepaintBoundary(
            child: RecipeCard(
              recipe: recipe,
              onTap: () => controller.openRecipeDetails(recipe),
            ),
          );
        },
        childCount: recipes.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
      ),
    );
  }

  Widget _buildPaginationControls(
    BuildContext context,
    RecipesController controller,
  ) {
    if (controller.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // prev button
          _buildPaginationButton(
            context,
            onPressed:
                controller.hasPreviousPage && !controller.isLoadingPage
                    ? controller.goToPreviousPage
                    : null,
            icon: Icons.chevron_left,
            isLoading: false,
          ),

          const SizedBox(width: 16),

          // page numbers
          Expanded(child: _buildPageNumbers(context, controller)),

          const SizedBox(width: 16),

          // next button
          _buildPaginationButton(
            context,
            onPressed:
                controller.hasNextPage && !controller.isLoadingPage
                    ? controller.goToNextPage
                    : null,
            icon: Icons.chevron_right,
            isLoading: controller.isLoadingPage,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton(
    BuildContext context, {
    required VoidCallback? onPressed,
    required IconData icon,
    required bool isLoading,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        onPressed != null
            ? AppColor.primaryOrange
            : (isDark ? AppColor.darkBorder : AppColor.neutralGrey200);
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child:
                isLoading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Icon(
                      icon,
                      color:
                          onPressed != null
                              ? Colors.white
                              : AppColor.neutralGrey400,
                      size: 24,
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumbers(BuildContext context, RecipesController controller) {
    final currentPage = controller.currentPageNumber;
    final totalPages = controller.totalPages;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (currentPage > 3) ...[
            _buildPageNumberButton(context, controller, 1),
            if (currentPage > 4)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '...',
                  style: TextStyle(color: AppColor.neutralGrey500),
                ),
              ),
          ],

          for (
            int i = (currentPage - 2).clamp(1, totalPages);
            i <= (currentPage + 2).clamp(1, totalPages);
            i++
          )
            _buildPageNumberButton(context, controller, i),

          if (currentPage < totalPages - 2) ...[
            if (currentPage < totalPages - 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '...',
                  style: TextStyle(color: AppColor.neutralGrey500),
                ),
              ),
            _buildPageNumberButton(context, controller, totalPages),
          ],
        ],
      ),
    );
  }

  Widget _buildPageNumberButton(
    BuildContext context,
    RecipesController controller,
    int pageNumber,
  ) {
    final isCurrentPage = pageNumber == controller.currentPageNumber;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isCurrentPage ? AppColor.primaryOrange : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap:
              controller.isLoadingPage
                  ? null
                  : () => controller.goToPage(pageNumber - 1),
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Text(
                pageNumber.toString(),
                style: context.theme.textTheme.titleSmall?.copyWith(
                  color: isCurrentPage ? Colors.white : AppColor.neutralGrey600,
                  fontWeight: isCurrentPage ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  SliverGrid _buildLoadingSliverGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildLoadingCard(context),
        childCount: 6,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.neutralGrey200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColor.primaryOrange,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColor.neutralGrey200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColor.neutralGrey200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
